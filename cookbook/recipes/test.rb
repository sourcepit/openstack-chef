openstack_identity 'create service user "glance"' do
  auth_uri "http://#{node['openstack']['controller']['host']}:35357/v2.0"
  admin_tenant "admin"
  admin_user node['openstack']['admin']['user']
  admin_password node['openstack']['admin']['password']
  
  user "glance"
  password node['openstack']['image']['service']['password']
  
  action :create_user
end