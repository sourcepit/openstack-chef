execute 'create_db' do
  command create_create_db_cmd(node['mariadb']['root_password'], "keystone", "keystone", "keystone")
  action :run
  notifies :restart, 'service[mariadb]', :immediately
end

%w(openstack-keystone python-keystoneclient).each do |pkg|
  package pkg do
    action :install
  end
end