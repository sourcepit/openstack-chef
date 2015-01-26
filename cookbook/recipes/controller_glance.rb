openstack_database 'create image db' do
  admin_password node['mariadb']['root_password']
  # create_db
  db_name 'glance'
  # grant_privileges
  user  node['openstack']['glance']['db']['user']
  password  node['openstack']['glance']['db']['password']

  action [:create_db, :grant_privileges]
  notifies :restart, 'service[mariadb]'
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
  admin_password node['openstack']['admin']['password']

  # user_create
  user node['openstack']['glance']['service']['user']
  password node['openstack']['glance']['service']['password']

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
  :db_url => create_db_url(node['mariadb']['host'], "glance", node['openstack']['glance']['db']['user'], node['openstack']['glance']['db']['password']),
  :verbose => node['openstack']['logging']['verbose'],
  :debug => node['openstack']['logging']['debug'],
  :keystone_auth_uri => "http://#{node['openstack']['controller']['host']}:5000/v2.0",
  :keystone_identity_uri => "http://#{node['openstack']['controller']['host']}:35357",
  :service_tenant => node['openstack']['service']['tenant'],
  :service_user => node['openstack']['glance']['service']['user'],
  :service_password => node['openstack']['glance']['service']['password']
  )
  action :create
end

template '/etc/glance/glance-registry.conf' do
  source 'glance-registry.conf.erb'
  variables(
  :db_url => create_db_url(node['mariadb']['host'], "glance", node['openstack']['glance']['db']['user'], node['openstack']['glance']['db']['password']),
  :verbose => node['openstack']['logging']['verbose'],
  :debug => node['openstack']['logging']['debug'],
  :keystone_auth_uri => "http://#{node['openstack']['controller']['host']}:5000/v2.0",
  :keystone_identity_uri => "http://#{node['openstack']['controller']['host']}:35357",
  :service_tenant => node['openstack']['service']['tenant'],
  :service_user => node['openstack']['glance']['service']['user'],
  :service_password => node['openstack']['glance']['service']['password']
  )
  action :create
end

execute 'sync image db' do
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
