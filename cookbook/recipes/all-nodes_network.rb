if_management = node['network']['management']['if']
ip_management = node['network']['management']['ip']

if_tunnel = ( node['network']['tunnel']['if'] == if_management ) ? nil : node['network']['tunnel']['if']
ip_tunnel = node['network']['tunnel']['ip']

if_external = ( node['network']['external']['if'] == if_management or node['network']['external']['if'] == if_tunnel ) ? nil : node['network']['external']['if']
ip_external = node['network']['external']['ip']

unless if_management.nil? or if_management.empty?
  template '/etc/sysconfig/network-scripts/ifcfg-' + if_management do
    source 'ifcfg.erb'
    variables(
    :DEVICE => if_management,
    :IPADDR => ip_management
    )
    notifies :restart, 'service[network]', :immediately
  end
end

unless if_tunnel.nil? or if_tunnel.empty?
  template '/etc/sysconfig/network-scripts/ifcfg-' + if_tunnel do
    source 'ifcfg.erb'
    variables(
    :DEVICE => if_tunnel,
    :IPADDR => ip_tunnel
    )
    notifies :restart, 'service[network]', :immediately
  end
end

unless if_external.nil? or if_external.empty?
  template '/etc/sysconfig/network-scripts/ifcfg-' + if_external do
    source 'ifcfg.erb'
    variables(
    :DEVICE => if_external,
    :IPADDR => ip_external
    )
    # first restart is expected to fail if if_external is configured without an ip address
    notifies :restart, 'service[network]', :immediately
    notifies :restart, 'service[network]', :immediately
  end
end

service 'network' do
  supports status: true, restart: true
  ignore_failure true
  action :nothing
end

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
