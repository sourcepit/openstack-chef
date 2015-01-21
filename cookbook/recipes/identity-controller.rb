execute 'create_db' do
  command create_create_db_cmd(node['mariadb']['root_password'], "keystone", node['openstack']['identity']['db']['user'], node['openstack']['identity']['db']['password'])
  action :run
  notifies :restart, 'service[mariadb]', :immediately
end

%w(openstack-keystone python-keystoneclient).each do |pkg|
  package pkg do
    action :install
  end
end

template '/etc/keystone/keystone.conf' do
  source 'keystone.conf.erb'
  variables(
  :db_url => create_db_url(node['mariadb']['host'], "keystone", node['openstack']['identity']['db']['user'], node['openstack']['identity']['db']['password']),
  :admin_token => node['openstack']['identity']['admin_token'],
  :verbose => node['openstack']['logging']['verbose'],
  :debug => node['openstack']['logging']['debug']
  )
  action :create
  notifies :run, 'bash[create generic certificates]', :immediately
  notifies :run, 'execute[db_sync]', :immediately
  notifies :run, 'execute[use cron to periodically purge expired tokens]', :immediately
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

execute 'use cron to periodically purge expired tokens' do
  command "(crontab -l -u keystone 2>&1 | grep -q token_flush) || echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/keystone"
  action :nothing
end

service 'openstack-keystone' do
  supports status: true, restart: true
  action [:enable, :start]
end

openstack_identity "create admin tenant, user and role" do
  auth_uri "http://#{node['openstack']['controller']['host']}:35357/v2.0"
  admin_token node['openstack']['identity']['admin_token']

  # tenant_create
  tenant_name node['openstack']['admin']['tenant']
  tenant_description "Admin Tenant"

  # user_create
  user node['openstack']['admin']['user']
  password node['openstack']['admin']['password']

  # role_create, user_role_add
  role 'admin'

  action [:tenant_create, :user_create, :role_create, :user_role_add]
end

openstack_identity "create service tenant" do
  auth_uri "http://#{node['openstack']['controller']['host']}:35357/v2.0"
  admin_tenant node['openstack']['admin']['tenant']
  admin_user node['openstack']['admin']['user']
  admin_password anode['openstack']['admin']['password']

  # tenant_create
  tenant_name node['openstack']['service']['tenant']
  tenant_description "Service Tenant"

  action [:tenant_create]
end

openstack_identity "create identity service and endpoint" do
  auth_uri "http://#{node['openstack']['controller']['host']}:35357/v2.0"
  admin_tenant node['openstack']['admin']['tenant']
  admin_user node['openstack']['admin']['user']
  admin_password anode['openstack']['admin']['password']

  # service_create
  service_name 'keystone'
  service_type 'identity'
  service_description 'OpenStack Identity Service'

  # endpoint_create
  endpoint_url "http://#{node['openstack']['controller']['host']}:5000/v2.0"
  endpoint_admin_url "http://#{node['openstack']['controller']['host']}:35357/v2.0"
  endpoint_region 'regionOne'

  action [:service_create, :endpoint_create]
end
