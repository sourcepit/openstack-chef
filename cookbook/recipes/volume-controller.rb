openstack_database 'create volume db' do
  admin_password node['mariadb']['root_password']

  # create_db
  db_name 'cinder'

  # grant_privileges
  user  node['openstack']['volume']['db']['user']
  password  node['openstack']['volume']['db']['password']

  action [:create_db, :grant_privileges]
  notifies :restart, 'service[mariadb]', :immediately
end

openstack_identity "create volume user and endpoint" do
  auth_uri "http://#{node['openstack']['controller']['host']}:35357/v2.0"
  admin_tenant node['openstack']['admin']['tenant']
  admin_user node['openstack']['admin']['user']
  admin_password node['openstack']['admin']['password']

  # user_create
  user node['openstack']['volume']['service']['user']
  password node['openstack']['volume']['service']['password']

  # user_role_add
  tenant_name node['openstack']['service']['tenant']
  role 'admin'

  # service_create
  service_name 'cinder'
  service_type 'volume'
  service_description 'OpenStack Block Storage Service'

  # endpoint_create
  endpoint_url "http://#{node['openstack']['controller']['host']}:8776/v1/%\\(tenant_id\\)s"
  endpoint_region 'regionOne'

  action [:user_create, :user_role_add, :service_create, :endpoint_create]
end

openstack_identity "create volumev2 user and endpoint" do
  auth_uri "http://#{node['openstack']['controller']['host']}:35357/v2.0"
  admin_tenant node['openstack']['admin']['tenant']
  admin_user node['openstack']['admin']['user']
  admin_password node['openstack']['admin']['password']

  # user_create
  user node['openstack']['volume']['service']['user']
  password node['openstack']['volume']['service']['password']

  # user_role_add
  tenant_name node['openstack']['service']['tenant']
  role 'admin'

  # service_create
  service_name 'cinderv2'
  service_type 'volumev2'
  service_description 'OpenStack Block Storage Service'

  # endpoint_create
  endpoint_url "http://#{node['openstack']['controller']['host']}:8776/v2/%\\(tenant_id\\)s"
  endpoint_region 'regionOne'

  action [:user_create, :user_role_add, :service_create, :endpoint_create]
end

%w(openstack-cinder python-cinderclient python-oslo-db).each do |pkg|
  package pkg do
    action :install
  end
end

template '/etc/cinder/cinder.conf' do
  source 'cinder.conf.erb'
  variables(
  :verbose => node['openstack']['logging']['verbose'],
  :debug => node['openstack']['logging']['debug'],
  :rabbit_host => node['openstack']['rabbitmq']['host'],
  :rabbit_userid => node['openstack']['rabbitmq']['user'],
  :rabbit_password => node['openstack']['rabbitmq']['password'],
  :my_ip => node['network']['ip_management'],
  :db_url => create_db_url(node['mariadb']['host'], "cinder", node['openstack']['volume']['db']['user'], node['openstack']['volume']['db']['password']),
  :glance_host => node['openstack']['controller']['host'],
  :keystone_auth_uri => "http://#{node['openstack']['controller']['host']}:5000/v2.0",
  :keystone_identity_uri => "http://#{node['openstack']['controller']['host']}:35357",
  :service_tenant => node['openstack']['service']['tenant'],
  :service_user => node['openstack']['volume']['service']['user'],
  :service_password => node['openstack']['volume']['service']['password']
  )
  action :create
end

# returns error if db is emty "Error: Upgrade DB using Essex release first."
#unless is_db_empty('root', node['mariadb']['root_password'], 'cinder')
  execute 'sync volume db' do
    command 'su -s /bin/sh -c "cinder-manage db sync" cinder'
    action :run
  end
#end

service 'openstack-cinder-api' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/cinder/cinder.conf]'
end

service 'openstack-cinder-scheduler' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/cinder/cinder.conf]'
end