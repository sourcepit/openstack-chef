openstack_database 'create network db' do
  admin_password node['mariadb']['root_password']
  # create_db
  db_name 'neutron'
  # grant_privileges
  user  node['openstack']['neutron']['db']['user']
  password  node['openstack']['neutron']['db']['password']

  action [:create_db, :grant_privileges]
  notifies :restart, 'service[mariadb]', :immediately
end

openstack_identity "create network service user and endpoint" do
  auth_uri "http://#{node['openstack']['controller']['host']}:35357/v2.0"
  admin_tenant node['openstack']['admin']['tenant']
  admin_user node['openstack']['admin']['user']
  admin_password node['openstack']['admin']['password']

  # user_create
  user node['openstack']['neutron']['service']['user']
  password node['openstack']['neutron']['service']['password']

  # user_role_add
  tenant_name node['openstack']['service']['tenant']
  role 'admin'

  # service_create
  service_name 'neutron'
  service_type 'network'
  service_description 'OpenStack Networking Service'

  # endpoint_create
  endpoint_url "http://#{node['openstack']['controller']['host']}:9696"
  endpoint_region 'regionOne'

  action [:user_create, :user_role_add, :service_create, :endpoint_create]
end

%w(openstack-neutron openstack-neutron-ml2 python-neutronclient which).each do |pkg|
  package pkg do
    action :install
  end
end

include_recipe 'openstack::internal_neutron-conf'

include_recipe 'openstack::internal_neutron-ml2-conf'

execute 'sync network db' do
  command 'su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade juno" neutron'
  action :run
end

service 'neutron-server' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/neutron/neutron.conf]', :immediately
  subscribes :restart, 'template[/etc/neutron/plugins/ml2/ml2_conf.ini]', :immediately
end