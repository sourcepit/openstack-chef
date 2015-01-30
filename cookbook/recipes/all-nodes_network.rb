if_management = node['network']['management']['if']
ip_management = node['network']['management']['ip']
gateway_management = node['network']['management']['gateway']

if_tunnel = ( node['network']['tunnel']['if'] == if_management ) ? nil : node['network']['tunnel']['if']
ip_tunnel = node['network']['tunnel']['ip']
gateway_tunnel = node['network']['tunnel']['gateway']

if_external = ( node['network']['external']['if'] == if_management or node['network']['external']['if'] == if_tunnel ) ? nil : node['network']['external']['if']
ip_external = node['network']['external']['ip']
gateway_external = node['network']['external']['gateway']

unless if_management.nil? or if_management.empty?
  template '/etc/sysconfig/network-scripts/ifcfg-' + if_management do
    source 'ifcfg.erb'
    variables(
    :DEVICE => if_management,
    :IPADDR => ip_management,
    :GATEWAY => gateway_management
    )
    notifies :restart, 'service[network]', :immediately
  end
end

unless if_tunnel.nil? or if_tunnel.empty?
  template '/etc/sysconfig/network-scripts/ifcfg-' + if_tunnel do
    source 'ifcfg.erb'
    variables(
    :DEVICE => if_tunnel,
    :IPADDR => ip_tunnel,
    :GATEWAY => gateway_tunnel
    )
    notifies :restart, 'service[network]', :immediately
  end
end

unless if_external.nil? or if_external.empty?
  template '/etc/sysconfig/network-scripts/ifcfg-' + if_external do
    source 'ifcfg.erb'
    variables(
    :DEVICE => if_external,
    :IPADDR => ip_external,
    :GATEWAY => gateway_external
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
