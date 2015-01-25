openstack_database 'create compute db' do
  admin_password node['mariadb']['root_password']
  # create_db
  db_name 'nova'
  # grant_privileges
  user  node['openstack']['nova']['db']['user']
  password  node['openstack']['nova']['db']['password']

  action [:create_db, :grant_privileges]
  notifies :restart, 'service[mariadb]', :immediately
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

template '/etc/nova/nova.conf' do
  source 'nova.conf.erb'
  variables(
  :verbose => node['openstack']['logging']['verbose'],
  :debug => node['openstack']['logging']['debug'],
  :rabbit_host => node['openstack']['rabbitmq']['host'],
  :rabbit_userid => node['openstack']['rabbitmq']['user'],
  :rabbit_password => node['openstack']['rabbitmq']['password'],
  :my_ip => node['network']['ip_management'],
  :vncserver_listen => node['openstack']['is_controller_node'] ? node['network']['ip_management'] : '0.0.0.0',
  :vncserver_proxyclient_address => node['network']['ip_management'],
  :novncproxy_base_url => node['openstack']['is_controller_node'] ? nil : "http://#{node['openstack']['controller']['host']}:6080/vnc_auto.html",
  :db_url => create_db_url(node['mariadb']['host'], "nova", node['openstack']['nova']['db']['user'], node['openstack']['nova']['db']['password']),
  :glance_host => node['openstack']['controller']['host'],
  :keystone_auth_uri => "http://#{node['openstack']['controller']['host']}:5000/v2.0",
  :keystone_identity_uri => "http://#{node['openstack']['controller']['host']}:35357",
  :service_tenant => node['openstack']['service']['tenant'],
  :service_user => node['openstack']['nova']['service']['user'],
  :service_password => node['openstack']['nova']['service']['password'],
  # neutron
  :neutron_url => "http://#{node['openstack']['controller']['host']}:9696",
  :neutron_admin_auth_url => "http://#{node['openstack']['controller']['host']}:35357/v2.0",
  :neutron_admin_tenant_name => node['openstack']['service']['tenant'],
  :neutron_admin_username => node['openstack']['neutron']['service']['user'],
  :neutron_admin_password => node['openstack']['neutron']['service']['user']
  )
  action :create
end

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