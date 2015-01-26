include_recipe 'openstack::internal_cinder-conf'

execute 'sync volume db' do
  command 'su -s /bin/sh -c "cinder-manage db sync" cinder'
  action :run
end

service 'openstack-cinder-volume' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/cinder/cinder.conf]'
end