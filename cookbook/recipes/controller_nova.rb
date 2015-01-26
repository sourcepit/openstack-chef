openstack_database 'create compute db' do
  admin_password node['mariadb']['root_password']
  # create_db
  db_name 'nova'
  # grant_privileges
  user  node['openstack']['nova']['db']['user']
  password  node['openstack']['nova']['db']['password']

  action [:create_db, :grant_privileges]
  notifies :restart, 'service[mariadb]'
end

openstack_identity "create compute service user and endpoint" do
  auth_uri "http://#{node['openstack']['controller']['host']}:35357/v2.0"
  admin_tenant node['openstack']['admin']['tenant']
  admin_user node['openstack']['admin']['user']
  admin_password node['openstack']['admin']['password']

  # user_create
  user node['openstack']['nova']['service']['user']
  password node['openstack']['nova']['service']['password']

  # user_role_add
  tenant_name node['openstack']['service']['tenant']
  role 'admin'

  # service_create
  service_name 'nova'
  service_type 'compute'
  service_description 'OpenStack Compute Service'

  # endpoint_create
  endpoint_url "http://#{node['openstack']['controller']['host']}:8774/v2/%\\(tenant_id\\)s"
  endpoint_region 'regionOne'

  action [:user_create, :user_role_add, :service_create, :endpoint_create]
end

%w(openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler python-novaclient).each do |pkg|
  package pkg do
    action :install
  end
end

include_recipe 'openstack::internal_nova-conf'

execute 'sync compute db' do
  command "su -s /bin/sh -c 'nova-manage db sync' nova"
  action :run
end

service 'openstack-nova-api' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/nova/nova.conf]'
end

service 'openstack-nova-cert' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/nova/nova.conf]'
end

service 'openstack-nova-consoleauth' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/nova/nova.conf]'
end

service 'openstack-nova-scheduler' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/nova/nova.conf]'
end

service 'openstack-nova-conductor' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/nova/nova.conf]'
end

service 'openstack-nova-novncproxy' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/nova/nova.conf]'
end