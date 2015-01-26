openstack_database 'create volume db' do
  admin_password node['mariadb']['root_password']
  # create_db
  db_name 'cinder'
  # grant_privileges
  user  node['openstack']['cinder']['db']['user']
  password  node['openstack']['cinder']['db']['password']

  action [:create_db, :grant_privileges]
  notifies :restart, 'service[mariadb]', :immediately
end

openstack_identity "create volume user and endpoint" do
  auth_uri "http://#{node['openstack']['controller']['host']}:35357/v2.0"
  admin_tenant node['openstack']['admin']['tenant']
  admin_user node['openstack']['admin']['user']
  admin_password node['openstack']['admin']['password']

  # user_create
  user node['openstack']['cinder']['service']['user']
  password node['openstack']['cinder']['service']['password']

  # user_role_add
  tenant_name node['openstack']['service']['tenant']
  role 'admin'

  # service_create
  service_name 'cinder'
  service_type 'volume'
  service_description 'OpenStack Block Storage Service'

  # endpoint_create
  endpoint_url "http://#{node['openstack']['controller']['host']}:8776/v1/%\\(tenant_id\\)s"
  endpoint_region 'regionOne'

  action [:user_create, :user_role_add, :service_create, :endpoint_create]
end

openstack_identity "create volumev2 user and endpoint" do
  auth_uri "http://#{node['openstack']['controller']['host']}:35357/v2.0"
  admin_tenant node['openstack']['admin']['tenant']
  admin_user node['openstack']['admin']['user']
  admin_password node['openstack']['admin']['password']

  # user_create
  user node['openstack']['cinder']['service']['user']
  password node['openstack']['cinder']['service']['password']

  # user_role_add
  tenant_name node['openstack']['service']['tenant']
  role 'admin'

  # service_create
  service_name 'cinderv2'
  service_type 'volumev2'
  service_description 'OpenStack Block Storage Service'

  # endpoint_create
  endpoint_url "http://#{node['openstack']['controller']['host']}:8776/v2/%\\(tenant_id\\)s"
  endpoint_region 'regionOne'

  action [:user_create, :user_role_add, :service_create, :endpoint_create]
end

%w(openstack-cinder python-cinderclient python-oslo-db).each do |pkg|
  package pkg do
    action :install
  end
end

include_recipe 'openstack::internal_cinder-conf'

execute 'sync volume db' do
  command 'su -s /bin/sh -c "cinder-manage db sync" cinder'
  action :run
end

service 'openstack-cinder-api' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/cinder/cinder.conf]'
end

service 'openstack-cinder-scheduler' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/cinder/cinder.conf]'
end