is_controller_node = node['openstack']['is_controller_node']
is_network_node = node['openstack']['is_network_node']
is_compute_node = node['openstack']['is_compute_node']
is_storage_node = node['openstack']['is_storage_node']

template '/etc/cinder/cinder.conf' do
  source 'cinder.conf.erb'
  variables(
  :is_controller_node => is_controller_node,
  :is_network_node => is_network_node,
  :is_compute_node => is_compute_node,
  :is_storage_node => is_storage_node,
  # debug
  :verbose => node['openstack']['logging']['verbose'],
  :debug => node['openstack']['logging']['debug'],
  # rabbitmq
  :rabbit_host => node['openstack']['rabbitmq']['host'],
  :rabbit_userid => node['openstack']['rabbitmq']['user'],
  :rabbit_password => node['openstack']['rabbitmq']['password'],
  # my_ip
  :my_ip => node['network']['management']['ip'],
  # db
  :db_url => create_db_url(node['openstack']['db']['host'], "cinder", node['openstack']['cinder']['db']['user'], node['openstack']['cinder']['db']['password']),
  # glance
  :glance_host => node['openstack']['controller']['host'],
  # keystone
  :keystone_auth_uri => "http://#{node['openstack']['controller']['host']}:5000/v2.0",
  :keystone_identity_uri => "http://#{node['openstack']['controller']['host']}:35357",
  :service_tenant => node['openstack']['service']['tenant'],
  :service_user => node['openstack']['cinder']['service']['user'],
  :service_password => node['openstack']['cinder']['service']['password']
  )
  action :create
end