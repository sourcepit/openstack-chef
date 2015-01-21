execute 'create_db' do
  command create_create_db_cmd(node['mariadb']['root_password'], "glance", node['openstack']['image']['db']['user'], node['openstack']['image']['db']['password'])
  action :run
  notifies :restart, 'service[mariadb]', :immediately
end

%w(openstack-glance python-glanceclient).each do |pkg|
  package pkg do
    action :install
  end
end

openstack_identity "create image service user and endpoint" do
  auth_uri "http://#{node['openstack']['controller']['host']}:35357/v2.0"
  admin_tenant node['openstack']['admin']['tenant']
  admin_user node['openstack']['admin']['user']
  admin_password anode['openstack']['admin']['password']

  # user_create
  user node['openstack']['image']['service']['user']
  password node['openstack']['image']['service']['password']

  # user_role_add
  tenant_name node['openstack']['service']['tenant']
  role 'admin'

  # service_create
  service_name 'glance'
  service_type 'image'
  service_description 'OpenStack Image Service'

  # endpoint_create
  endpoint_url "http://#{node['openstack']['controller']['host']}:9292"
  endpoint_region 'regionOne'

  action [:user_create, :user_role_add, :service_create, :endpoint_create]
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
  action :create
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
  action :create
end

execute 'db_sync' do
  command "su -s /bin/sh -c 'glance-manage db_sync' glance"
  action :run
end

service 'openstack-glance-api' do
  supports status: true, restart: true
  action [:enable, :start]
end

service 'openstack-glance-registry' do
  supports status: true, restart: true
  action [:enable, :start]
end
