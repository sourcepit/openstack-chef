openstack_database 'create identity db' do
  admin_password node['mariadb']['root_password']
  # create_db
  db_name 'keystone'
  # grant_privileges
  user  node['openstack']['keystone']['db']['user']
  password  node['openstack']['keystone']['db']['password']

  action [:create_db, :grant_privileges]
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
  :db_url => create_db_url(node['openstack']['db']['host'], "keystone", node['openstack']['keystone']['db']['user'], node['openstack']['keystone']['db']['password']),
  :admin_token => node['openstack']['keystone']['admin_token'],
  :verbose => node['openstack']['logging']['verbose'],
  :debug => node['openstack']['logging']['debug']
  )
  action :create
  notifies :run, 'bash[create generic certificates]', :immediately
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

execute 'sync identity db' do
  command "su -s /bin/sh -c 'keystone-manage db_sync' keystone"
  action :run
end

execute 'use cron to periodically purge expired tokens' do
  command "(crontab -l -u keystone 2>&1 | grep -q token_flush) || echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/keystone"
  action :run
end

service 'openstack-keystone' do
  supports status: true, restart: true
  action [:enable, :start]
end

openstack_identity "create admin tenant, user and role" do
  auth_uri "http://#{node['openstack']['controller']['host']}:35357/v2.0"
  admin_token node['openstack']['keystone']['admin_token']

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
  admin_token node['openstack']['keystone']['admin_token']

  # tenant_create
  tenant_name node['openstack']['service']['tenant']
  tenant_description "Service Tenant"

  action [:tenant_create]
end

openstack_identity "create identity service and endpoint" do
  auth_uri "http://#{node['openstack']['controller']['host']}:35357/v2.0"
  admin_token node['openstack']['keystone']['admin_token']

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
