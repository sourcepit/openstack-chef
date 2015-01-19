node.override['mariadb']['server_root_password'] = node['openstack']['mariadb']['root_password']
node.override['mariadb']['allow_root_pass_change'] = node['openstack']['mariadb']['allow_root_pass_change']

include_recipe "mariadb::server"