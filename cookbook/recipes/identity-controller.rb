execute 'create_db' do
  command Openstack::DBHelper.create_create_db_cmd(node['mariadb']['root_password'], "keystone", "keystone", "keystone")
  action :run
  notifies :restart, 'service[mariadb]', :immediately
end
