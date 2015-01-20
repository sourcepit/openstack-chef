execute 'create_db' do
  command create_create_db_cmd(node['mariadb']['root_password'], "keystone", node['openstack']['keystone']['db']['user'], node['openstack']['keystone']['db']['password'])
  action :run
  notifies :restart, 'service[mariadb]', :immediately
end

%w(openstack-keystone python-keystoneclient).each do |pkg|
  package pkg do
    action :install
    notifies :run, 'template[/etc/keystone/keystone.conf]', :immediately
  end
end

template '/etc/keystone/keystone.conf' do
  source 'keystone.conf.erb'
  variables(
  :db_url => create_db_url(node['mariadb']['host'], "keystone", node['openstack']['keystone']['db']['user'], node['openstack']['keystone']['db']['password']),
  :admin_token => node['openstack']['keystone']['admin_token'],
  :verbose => node['openstack']['logging']['verbose'],
  :debug => node['openstack']['logging']['debug']
  )
  action :nothing
  notifies :run, 'bash[create generic certificates]', :immediately
  notifies :run, 'execute[db_sync]', :immediately
  notifies :enable, 'service[openstack-keystone]', :immediately
  notifies :start, 'service[openstack-keystone]', :immediately
  notifies :run, 'execute[use cron to periodically purge expired tokens]', :immediately
  notifies :run, 'bash[create admin and service tenants]', :immediately
  notifies :run, 'bash[create the service entity and API endpoints]', :immediately
end

bash 'create generic certificates' do
  code <<-EOH
keystone-manage pki_setup --keystone-user keystone --keystone-group keystone
chown -R keystone:keystone /var/log/keystone
chown -R keystone:keystone /etc/keystone/ssl
chmod -R o-rwx /etc/keystone/ssl
  EOH
  action :nothing
end

execute 'db_sync' do
  command "su -s /bin/sh -c 'keystone-manage db_sync' keystone"
  action :nothing
end

service 'openstack-keystone' do
  supports status: true, restart: true
  action :nothing
end

execute 'use cron to periodically purge expired tokens' do
  command "(crontab -l -u keystone 2>&1 | grep -q token_flush) || echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/keystone"
  action :nothing
end

bash 'create admin and service tenants' do
  code <<-EOH
export OS_SERVICE_TOKEN=#{node['openstack']['keystone']['admin_token']}
export OS_SERVICE_ENDPOINT=http://#{node['openstack']['controller']['host']}:35357/v2.0

keystone tenant-create --name admin --description "Admin Tenant"
keystone user-create --name #{node['openstack']['admin']['user']} --pass #{node['openstack']['admin']['password']} --email #{node['openstack']['admin']['email']}
keystone role-create --name admin
keystone user-role-add --user #{node['openstack']['admin']['user']} --tenant admin --role admin

keystone tenant-create --name service --description "Service Tenant"
  EOH
  action :nothing
end

bash 'create the service entity and API endpoints' do
  code <<-EOH
export OS_SERVICE_TOKEN=#{node['openstack']['keystone']['admin_token']}
export OS_SERVICE_ENDPOINT=http://#{node['openstack']['controller']['host']}:35357/v2.0
  
keystone service-create --name keystone --type identity --description "OpenStack Identity"
    
keystone endpoint-create \
  --service-id $(keystone service-list | awk '/ identity / {print $2}') \
  --publicurl http://#{node['openstack']['controller']['host']}:5000/v2.0 \
  --internalurl http://#{node['openstack']['controller']['host']}:5000/v2.0 \
  --adminurl http://#{node['openstack']['controller']['host']}:35357/v2.0 \
  --region regionOne
  EOH
  action :nothing
end
