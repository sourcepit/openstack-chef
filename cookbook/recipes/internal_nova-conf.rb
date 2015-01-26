is_controller_node = node['openstack']['is_controller_node']
is_network_node = node['openstack']['is_network_node']
is_compute_node = node['openstack']['is_compute_node']

template '/etc/nova/nova.conf' do
  source 'nova.conf.erb'
  variables(
  :is_controller_node => is_network_node,
  :is_network_node => is_network_node,
  :is_compute_node => is_compute_node,
  # debug
  :verbose => node['openstack']['logging']['verbose'],
  :debug => node['openstack']['logging']['debug'],
  # rabbitmq
  :rabbit_host => node['openstack']['rabbitmq']['host'],
  :rabbit_userid => node['openstack']['rabbitmq']['user'],
  :rabbit_password => node['openstack']['rabbitmq']['password'],
  # my_op
  :my_ip => node['network']['management']['ip'],
  # vnc
  :vncserver_listen => is_controller_node ? node['network']['management']['ip'] : '0.0.0.0',
  :vncserver_proxyclient_address => node['network']['management']['ip'],
  :novncproxy_base_url => is_compute_node ? "http://#{node['openstack']['controller']['host']}:6080/vnc_auto.html" : nil,
  #db
  :db_url => is_controller_node ? create_db_url(node['mariadb']['host'], "nova", node['openstack']['nova']['db']['user'], node['openstack']['nova']['db']['password']) : nil,
  #glance
  :glance_host => node['openstack']['controller']['host'],
  # keystone
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
  :neutron_admin_password => node['openstack']['neutron']['service']['user'],
  :metadata_proxy_shared_secret =>  is_controller_node ? node['openstack']['neutron']['metadata']['shared_secret'] : nil,
  # virt_type
  :virt_type => determine_virt_type
  )
  action :create
end