%w(openstack-neutron-ml2 openstack-neutron-openvswitch).each do |pkg|
  package pkg do
    action :install
  end
end

include_recipe 'openstack::internal_neutron-conf'

include_recipe 'openstack::internal_neutron-ml2-conf'

service 'openvswitch' do
  supports status: true, restart: true
  action [:enable, :start]
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
  subscribes :restart, 'template[/etc/neutron/neutron.conf]'
  subscribes :restart, 'template[/etc/neutron/plugins/ml2/ml2_conf.ini]'
end