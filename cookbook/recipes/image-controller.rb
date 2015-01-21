auth_uri = "http://#{node['openstack']['controller']['host']}:35357/v2.0"

admin_tenant = node['openstack']['admin']['tenant']
admin_user = node['openstack']['admin']['user']
admin_password = node['openstack']['admin']['password']

service_tenant = node['openstack']['service']['tenant']
service_user = node['openstack']['image']['service']['user']
service_password = node['openstack']['image']['service']['password']

execute 'create_db' do
  command create_create_db_cmd(node['mariadb']['root_password'], "glance", node['openstack']['image']['db']['user'], node['openstack']['image']['db']['password'])
  action :run
  notifies :restart, 'service[mariadb]', :immediately
end

%w(openstack-glance python-glanceclient).each do |pkg|
  package pkg do
    action :install
    notifies :run, 'bash[create service endpoint]', :immediately
    notifies :create, 'template[/etc/glance/glance-api.conf]', :immediately
    notifies :create, 'template[/etc/glance/glance-registry.conf]', :immediately
    notifies :run, 'execute[db_sync]', :immediately
    notifies :enable, 'service[openstack-glance-api]', :immediately
    notifies :start, 'service[openstack-glance-api]', :immediately
    notifies :enable, 'service[openstack-glance-registry]', :immediately
    notifies :start, 'service[openstack-glance-registry]', :immediately
  end
end

openstack_identity "create image service user and endpoint" do
  auth_uri auth_uri
  admin_tenant admin_tenant
  admin_user admin_user
  admin_password admin_password

  # create_user
  user service_user
  password service_password

  # user_role_add
  tenant service_tenant
  role 'admin'
  
  # service_create
  service_name 'glance'
  service_type 'image'
  service_description 'OpenStack Image Service'
  
  # endpoint_create
  endpoint_url "http://#{node['openstack']['controller']['host']}:9292"
  endpoint_region 'regionOne'

  action [:create_user, :user_role_add, :service_create, :endpoint_create]
end

bash 'create service endpoint' do
  code <<-EOH
  export OS_TENANT_NAME=admin
  export OS_USERNAME=#{node['openstack']['admin']['user']}
  export OS_PASSWORD=#{node['openstack']['admin']['password']}
  export OS_AUTH_URL=http://#{node['openstack']['controller']['host']}:35357/v2.0

  keystone user-create --name glance --pass #{node['openstack']['image']['service']['password']} 
  keystone user-role-add --user glance --tenant service --role admin
  keystone service-create --name glance --type image --description "OpenStack Image Service"
    
  keystone endpoint-create \
    --service-id $(keystone service-list | awk '/ image / {print $2}') \
    --publicurl http://#{node['openstack']['controller']['host']}:9292 \
    --internalurl http://#{node['openstack']['controller']['host']}:9292 \
    --adminurl http://#{node['openstack']['controller']['host']}:9292 \
    --region regionOne
  EOH
  action :nothing
end

template '/etc/glance/glance-api.conf' do
  source 'glance-api.conf.erb'
  variables(
  :db_url => create_db_url(node['mariadb']['host'], "glance", node['openstack']['image']['db']['user'], node['openstack']['image']['db']['password']),
  :verbose => node['openstack']['logging']['verbose'],
  :debug => node['openstack']['logging']['debug'],
  :keystone_auth_uri => "http://#{node['openstack']['controller']['host']}:5000/v2.0",
  :keystone_identity_uri => "http://#{node['openstack']['controller']['host']}:35357",
  :service_user => "glance",
  :service_password => node['openstack']['image']['service']['password']
  )
  action :nothing
end

template '/etc/glance/glance-registry.conf' do
  source 'glance-registry.conf.erb'
  variables(
  :db_url => create_db_url(node['mariadb']['host'], "glance", node['openstack']['image']['db']['user'], node['openstack']['image']['db']['password']),
  :verbose => node['openstack']['logging']['verbose'],
  :debug => node['openstack']['logging']['debug'],
  :keystone_auth_uri => "http://#{node['openstack']['controller']['host']}:5000/v2.0",
  :keystone_identity_uri => "http://#{node['openstack']['controller']['host']}:35357",
  :service_user => "glance",
  :service_password => node['openstack']['image']['service']['password']
  )
  action :nothing
end

execute 'db_sync' do
  command "su -s /bin/sh -c 'glance-manage db_sync' glance"
  action :nothing
end

service 'openstack-glance-api' do
  supports status: true, restart: true
  action :nothing
end

service 'openstack-glance-registry' do
  supports status: true, restart: true
  action :nothing
end
