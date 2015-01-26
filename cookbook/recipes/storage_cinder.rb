include_recipe 'openstack::internal_cinder-conf'

service 'openstack-cinder-volume' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/cinder/cinder.conf]'
end