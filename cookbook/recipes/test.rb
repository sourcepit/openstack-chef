auth_uri = "http://#{node['openstack']['controller']['host']}:35357/v2.0"

admin_tenant = node['openstack']['admin']['tenant']
admin_user = node['openstack']['admin']['user']
admin_password = node['openstack']['admin']['password']

service_user = node['openstack']['image']['service']['user']
service_password = node['openstack']['image']['service']['password']

openstack_identity "create service user '#{service_user}'" do
  auth_uri auth_uri
  admin_tenant admin_tenant
  admin_user admin_user
  admin_password admin_password

  user service_user
  password service_password
  
  tenant 'service'
  role 'admin'

  action [:create_user, user_role_add]
end