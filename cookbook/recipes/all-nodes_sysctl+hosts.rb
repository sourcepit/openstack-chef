template '/etc/sysctl.conf' do
  source 'sysctl.conf.erb'
  variables(
  :is_network_node => node['openstack']['is_network_node']
  )
  action :create
  notifies :run, 'execute[sysctl]', :immediately
  only_if do
    node['openstack']['is_network_node'] or node['openstack']['is_compute_node']
  end
end

execute 'sysctl' do
  command 'sysctl -p'
  action :nothing
end

template '/etc/hosts' do
  source 'hosts.erb'
end
