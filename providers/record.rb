require "fog"
require "nokogiri"

def name
  @name ||= new_resource.name + "."
end

def value
  @value ||= new_resource.value
end

def type
  @type ||= new_resource.type
end

def ttl
  @ttl ||= new_resource.ttl
end

def zone
  @zone ||= Fog::DNS.new({ :provider => "aws",
                           :aws_access_key_id => new_resource.aws_access_key_id,
                           :aws_secret_access_key => new_resource.aws_secret_access_key }
                         ).zones.get( new_resource.zone_id )
end

action :create do
  def create
    begin
      zone.records.create({ :name => name,
                            :value => value,
                            :type => type,
                            :ttl => ttl })
    rescue Excon::Errors::BadRequest => e
      Chef::Log.info Nokogiri::XML( e.response.body ).xpath( "//xmlns:Message" ).text
    end
  end

  record = zone.records.all.select do |record|
    record.name == name
  end.first

  if record.nil?
    create
    Chef::Log.info "Record created: #{name}"
  elsif value != record.value.first
    record.destroy
    create
    Chef::Log.info "Record modified: #{name}"
  end
end

action :destroy do
 
  record = zone.records.all.select do |record|
    record.name == name
  end.first

  if record.nil?
    Chef::Log.info "Record #{name} don't exist!"
  elsif value != record.value.first
    record.destroy
    Chef::Log.info "Record destroyed: #{name}"
  end
end
