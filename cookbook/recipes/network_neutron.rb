%w(openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch).each do |pkg|
  package pkg do
    action :install
  end
end

include_recipe 'openstack::internal_neutron-conf'

include_recipe 'openstack::internal_neutron-ml2-conf'

template '/etc/neutron/l3_agent.ini' do
  source 'l3_agent.ini.erb'
  action :create
end

template '/etc/neutron/dhcp_agent.ini' do
  source 'dhcp_agent.ini.erb'
  action :create
end

template '/etc/neutron/dnsmasq-neutron.conf' do
  source 'dnsmasq-neutron.conf.erb'
  action :create
end

execute 'pkill dnsmasq' do
  user 'root'
  command 'pkill dnsmasq'
  ignore_failure true
  action :run
end

template '/etc/neutron/metadata_agent.ini' do
  source 'metadata_agent.ini.erb'
  variables(
  lazy {{
      # debug
      :verbose => node['openstack']['logging']['verbose'],
      :debug => node['openstack']['logging']['debug'],
      :nova_metadata_ip => node['openstack']['controller']['host'],
      # keystone
      :keystone_auth_uri => "http://#{node['openstack']['controller']['host']}:5000/v2.0",
      :service_tenant => node['openstack']['service']['tenant'],
      :service_user => node['openstack']['neutron']['service']['user'],
      :service_password => node['openstack']['neutron']['service']['password'],
      :metadata_proxy_shared_secret => node['openstack']['neutron']['metadata']['shared_secret']
    }}
  )
  action :create
end

service 'openvswitch' do
  supports status: true, restart: true
  action [:enable, :start]
end

openstack_ovs 'Create Open vSwitch bridge for external network' do
  bridge 'br-ex'
  port node['network']['if_external']
  action [:add_br, :add_port]
end