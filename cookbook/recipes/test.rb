auth_uri = "http://#{node['openstack']['controller']['host']}:35357/v2.0"

admin_tenant = node['openstack']['admin']['tenant']
admin_user = node['openstack']['admin']['user']
admin_password = node['openstack']['admin']['password']

service_user = node['openstack']['image']['service']['user']
service_password = node['openstack']['image']['service']['password']

openstack_identity "create service user '#{service_user}'" do
  auth_uri auth_uri
  admin_tenant admin_tenant
  admin_user admin_user
  admin_password admin_password

  # create_user
  user "bar"
  password "bar"

  # user_role_add
  tenant "service"
  role 'admin'
  
  # service_create
  service_name 'bar'
  service_type 'bar'
  service_description 'OpenStack bar Service'
  
  # endpoint_create
  endpoint_url "http://#{node['openstack']['controller']['host']}:9292"
  endpoint_region 'regionOne'

  action [:create_user, :user_role_add, :service_create, :endpoint_create]
  
  notifies :run, 'ruby_block[bar]', :immediately
end

ruby_block "bar" do
  block do
    puts "bar"
  end
  action :nothing
end