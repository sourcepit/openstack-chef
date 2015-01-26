is_controller_node = node['openstack']['is_controller_node']
is_network_node = node['openstack']['is_network_node']
is_compute_node = node['openstack']['is_compute_node']

template '/etc/neutron/neutron.conf' do
  source 'neutron.conf.erb'
  variables(
  lazy {{
      :is_controller_node => is_controller_node,
      :is_network_node => is_network_node,
      :is_compute_node => is_compute_node,
      # debug
      :verbose => node['openstack']['logging']['verbose'],
      :debug => node['openstack']['logging']['debug'],
      # rabbitmq
      :rabbit_host => node['openstack']['rabbitmq']['host'],
      :rabbit_userid => node['openstack']['rabbitmq']['user'],
      :rabbit_password => node['openstack']['rabbitmq']['password'],
      # nova
      :nova_url => is_controller_node ? "http://#{node['openstack']['controller']['host']}:8774/v2" : nil,
      :nova_admin_auth_url => is_controller_node ? "http://#{node['openstack']['controller']['host']}:35357/v2.0": nil,
      :nova_admin_username => is_controller_node ? node['openstack']['nova']['service']['user']: nil,
      :nova_admin_tenant_id =>  is_controller_node ? get_tenant_id(node['openstack']['admin']['tenant'], node['openstack']['admin']['user'], node['openstack']['admin']['password'], "http://#{node['openstack']['controller']['host']}:35357/v2.0", node['openstack']['service']['tenant']) : nil,
      :nova_admin_password => is_controller_node ? node['openstack']['nova']['service']['password']: nil,
      # db
      :db_url => is_controller_node ? create_db_url(node['openstack']['db']['host'], "neutron", node['openstack']['neutron']['db']['user'], node['openstack']['neutron']['db']['password']) : nil,
      # keystone
      :keystone_auth_uri => "http://#{node['openstack']['controller']['host']}:5000/v2.0",
      :keystone_identity_uri => "http://#{node['openstack']['controller']['host']}:35357",
      :service_tenant => node['openstack']['service']['tenant'],
      :service_user => node['openstack']['neutron']['service']['user'],
      :service_password => node['openstack']['neutron']['service']['password']
    }}
  )
  action :create
end