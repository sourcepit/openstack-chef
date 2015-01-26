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

execute 'fix packaging bug of Open vSwitch agent' do
  command <<-eos
    cp /usr/lib/systemd/system/neutron-openvswitch-agent.service /usr/lib/systemd/system/neutron-openvswitch-agent.service.orig
    sed -i 's,plugins/openvswitch/ovs_neutron_plugin.ini,plugin.ini,g' /usr/lib/systemd/system/neutron-openvswitch-agent.service
  eos
  action :run
  not_if { ::File.exists?('/usr/lib/systemd/system/neutron-openvswitch-agent.service.orig')}
end

service 'neutron-openvswitch-agent' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/neutron/neutron.conf]', :immediately
  subscribes :restart, 'template[/etc/neutron/plugins/ml2/ml2_conf.ini]', :immediately
  subscribes :restart, 'template[/etc/neutron/l3_agent.ini]', :immediately
  subscribes :restart, 'template[/etc/neutron/dhcp_agent.ini]', :immediately
end

service 'neutron-l3-agent' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/neutron/neutron.conf]', :immediately
  subscribes :restart, 'template[/etc/neutron/plugins/ml2/ml2_conf.ini]', :immediately
  subscribes :restart, 'template[/etc/neutron/l3_agent.ini]', :immediately
  subscribes :restart, 'template[/etc/neutron/dhcp_agent.ini]', :immediately
end

service 'neutron-dhcp-agent' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/neutron/neutron.conf]', :immediately
  subscribes :restart, 'template[/etc/neutron/plugins/ml2/ml2_conf.ini]', :immediately
  subscribes :restart, 'template[/etc/neutron/l3_agent.ini]', :immediately
  subscribes :restart, 'template[/etc/neutron/dhcp_agent.ini]', :immediately
end

service 'neutron-metadata-agent' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/neutron/neutron.conf]', :immediately
  subscribes :restart, 'template[/etc/neutron/plugins/ml2/ml2_conf.ini]', :immediately
  subscribes :restart, 'template[/etc/neutron/l3_agent.ini]', :immediately
  subscribes :restart, 'template[/etc/neutron/dhcp_agent.ini]', :immediately
end

service 'neutron-ovs-cleanup' do
  supports status: true, restart: true
  action :enable
end