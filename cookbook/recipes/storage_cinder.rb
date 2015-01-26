%w(lvm2 openstack-cinder targetcli python-oslo-db MySQL-python).each do |pkg|
  package pkg do
    action :install
  end
end

include_recipe 'openstack::internal_cinder-conf'

service 'openstack-cinder-volume' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/cinder/cinder.conf]'
end