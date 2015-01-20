if_management = node['network']['if_management']
ip_management = node['network']['ip_management']

if_tunnel = ( node['network']['if_tunnel'] == if_management ) ? nil : node['network']['if_tunnel']
ip_tunnel = node['network']['ip_tunnel']

if_external = ( node['network']['if_external'] == if_management or node['network']['if_external'] == if_tunnel ) ? nil : node['network']['if_external']
ip_external = node['network']['ip_external']

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
