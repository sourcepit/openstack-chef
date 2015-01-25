is_controller_node = node['openstack']['is_controller_node']
is_network_node = node['openstack']['is_network_node']
is_compute_node = node['openstack']['is_compute_node']

template '/etc/neutron/plugins/ml2/ml2_conf.ini' do
  source 'ml2_conf.ini.erb'
  variables(
  :is_controller_node => is_controller_node,
  :is_network_node => is_network_node,
  :is_compute_node => is_compute_node,
  :local_ip=> node['network']['ip_tunnel']
  )
  action :create
end

execute '/etc/neutron/plugin.ini' do
  command 'ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini'
  action :run
  not_if do ::File.exists?('/etc/neutron/plugin.ini') end
end