node.override['mariadb']['server_root_password'] = node['openstack']['mariadb']['root_password']
node.override['mariadb']['allow_root_pass_change'] = node['openstack']['mariadb']['allow_root_pass_change']
node.override['mariadb']['install']['version'] = '10.1'
node.override['mariadb']['use_default_repository'] = true

include_recipe "mariadb::server"