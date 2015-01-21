execute 'create network db' do
  command create_create_db_cmd(node['mariadb']['root_password'], "neutron", node['openstack']['network']['db']['user'], node['openstack']['network']['db']['password'])
  action :run
  notifies :restart, 'service[mariadb]', :immediately
end

openstack_identity "create network service user and endpoint" do
  auth_uri "http://#{node['openstack']['controller']['host']}:35357/v2.0"
  admin_tenant node['openstack']['admin']['tenant']
  admin_user node['openstack']['admin']['user']
  admin_password node['openstack']['admin']['password']

  # user_create
  user node['openstack']['network']['service']['user']
  password node['openstack']['network']['service']['password']

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

if node['openstack']['is_network_node'] or node['openstack']['is_compute_node']
  template '/etc/sysctl.conf' do
    source 'sysctl.conf.erb'
    variables(
    :is_network_node => node['openstack']['is_network_node']
    )
    action :create
    notifies :run, 'execute[sysctl]', :immediately
  end
  execute 'sysctl' do
    command 'sysctl -p'
    action :nothing
  end
end

%w(openstack-neutron openstack-neutron-ml2 python-neutronclient which).each do |pkg|
  package pkg do
    action :install
  end
end

template '/etc/neutron/neutron.conf' do
  source 'neutron.conf.erb'
  variables(
  :verbose => node['openstack']['logging']['verbose'],
  :debug => node['openstack']['logging']['debug'],
  # rabbitmq
  :rabbit_host => node['openstack']['rabbitmq']['host'],
  :rabbit_userid => node['openstack']['rabbitmq']['user'],
  :rabbit_password => node['openstack']['rabbitmq']['password'],
  # nova
  :nova_url => "http://#{node['openstack']['controller']['host']}:8774/v2",
  :nova_admin_auth_url => "http://#{node['openstack']['controller']['host']}:35357/v2.0",
  :nova_admin_username => node['openstack']['compute']['service']['user'],
  :nova_admin_tenant_id => get_tenant_id(node['openstack']['admin']['tenant'], node['openstack']['admin']['user'], node['openstack']['admin']['password'], "http://#{node['openstack']['controller']['host']}:35357/v2.0", node['openstack']['service']['tenant']),
  :nova_admin_password => node['openstack']['compute']['service']['password'],
  # db
  :db_url => create_db_url(node['mariadb']['host'], "neutron", node['openstack']['network']['db']['user'], node['openstack']['network']['db']['password']),
  # keystone
  :keystone_auth_uri => "http://#{node['openstack']['controller']['host']}:5000/v2.0",
  :keystone_identity_uri => "http://#{node['openstack']['controller']['host']}:35357",
  :service_tenant => node['openstack']['service']['tenant'],
  :service_user => node['openstack']['network']['service']['user'],
  :service_password => node['openstack']['network']['service']['password']
  )
  action :create
end

template '/etc/neutron/plugins/ml2/ml2_conf.ini' do
  source 'ml2_conf.ini.erb'
  variables(
  :is_network_node => default['openstack']['is_network_node'],
  :is_compute_node => default['openstack']['is_compute_node'],
  :local_ip=> node['network']['ip_tunnel']
  )
  action :create
end

execute '/etc/neutron/plugin.ini' do
  command 'ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini'
  action :run
  not_if do ::File.exists?('/etc/neutron/plugin.ini') end
end

execute 'sync network db' do
  command 'su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade juno" neutron'
  action :run
end

service 'neutron-server' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/neutron/neutron.conf]'
  subscribes :restart, 'template[/etc/neutron/plugins/ml2/ml2_conf.ini]'
end