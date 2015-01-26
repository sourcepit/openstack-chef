%w(openstack-nova-compute sysfsutils).each do |pkg|
  package pkg do
    action :install
  end
end

include_recipe 'openstack::internal_nova-conf'

service 'libvirtd' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/nova/nova.conf]'
end

service 'openstack-nova-compute' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/nova/nova.conf]'
end