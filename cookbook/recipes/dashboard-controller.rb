%w(openstack-dashboard httpd mod_wsgi memcached python-memcached).each do |pkg|
  package pkg do
    action :install
  end
end

template '/etc/openstack-dashboard/local_settings' do
  source 'local_settings.erb'
  variables(
  :debug => node['openstack']['logging']['debug'] ? 'True' : 'False',
  :openstack_host => node['openstack']['controller']['host'],
  :time_zone => 'UTC'
  )
  action :create
end

execute 'setsebool -P httpd_can_network_connect on' do
  command 'setsebool -P httpd_can_network_connect on'
  action :run 
end

execute 'chown -R apache:apache /usr/share/openstack-dashboard/static' do
  command 'chown -R apache:apache /usr/share/openstack-dashboard/static'
  action :run 
end

service 'httpd' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/openstack-dashboard/local_settings]'
end
