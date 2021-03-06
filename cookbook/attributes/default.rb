default['network']['management']['if'] = nil
default['network']['tunnel']['if'] = nil
default['network']['external']['if'] = nil

default['network']['management']['ip'] = nil
default['network']['tunnel']['ip'] = nil
default['network']['external']['ip'] = nil

default['network']['management']['hosts'] = nil

default['mariadb']['root_password']  = ''
default['mariadb']['bind_address']  = ''
default['mariadb']['host']  = node['mariadb']['bind_address']

default['rabbitmq']['bind_address'] = ''
default['rabbitmq']['user'] = ''
default['rabbitmq']['password'] = ''

default['openstack']['logging']['verbose'] = 'false'
default['openstack']['logging']['debug'] = 'false'

default['openstack']['controller']['ip'] = node['network']['management']['ip']

default['openstack']['is_controller_node'] = node['openstack']['controller']['ip'] == node['network']['management']['ip']
default['openstack']['is_network_node'] = node.recipes.include?('openstack::network_neutron')
default['openstack']['is_compute_node'] = node.recipes.include?('openstack::compute_nova')
default['openstack']['is_storage_node'] = node.recipes.include?('openstack::storage_cinder')

default['openstack']['controller']['hosts'] = node['openstack']['is_controller_node'] ? node['network']['management']['hosts'] : nil
default['openstack']['controller']['host'] = node['openstack']['controller']['hosts'].nil? ? nil : node['openstack']['controller']['hosts'][0]

default['openstack']['rabbitmq']['host'] = node['openstack']['controller']['host']
default['openstack']['rabbitmq']['user'] = node['rabbitmq']['user']
default['openstack']['rabbitmq']['password'] = node['rabbitmq']['password']
  
default['openstack']['db']['host'] = node['openstack']['controller']['host']
default['openstack']['db']['user'] = 'admin'
default['openstack']['db']['password'] = 'secret'

default['openstack']['admin']['tenant'] = 'admin'
default['openstack']['admin']['user'] = 'admin'
default['openstack']['admin']['password'] = 'secret'

default['openstack']['service']['tenant'] = 'service'
default['openstack']['service']['user'] = 'service'
default['openstack']['service']['password'] = 'secret'

default['openstack']['keystone']['db']['user'] = node['openstack']['db']['user']
default['openstack']['keystone']['db']['password'] = node['openstack']['db']['password']
default['openstack']['keystone']['admin_token'] = '17986b3c37e2b95dcf03'

default['openstack']['glance']['db']['user'] = node['openstack']['db']['user']
default['openstack']['glance']['db']['password'] = node['openstack']['db']['password']
default['openstack']['glance']['service']['user'] = node['openstack']['service']['user']
default['openstack']['glance']['service']['password'] = node['openstack']['service']['password']

default['openstack']['nova']['db']['user'] = node['openstack']['db']['user']
default['openstack']['nova']['db']['password'] = node['openstack']['db']['password']
default['openstack']['nova']['service']['user'] = node['openstack']['service']['user']
default['openstack']['nova']['service']['password'] = node['openstack']['service']['password']

default['openstack']['neutron']['db']['user'] = node['openstack']['db']['user']
default['openstack']['neutron']['db']['password'] = node['openstack']['db']['password']
default['openstack']['neutron']['service']['user'] = node['openstack']['service']['user']
default['openstack']['neutron']['service']['password'] = node['openstack']['service']['password']
default['openstack']['neutron']['metadata']['shared_secret'] = 'ccac98a6e7329c213f06'

default['openstack']['cinder']['db']['user'] = node['openstack']['db']['user']
default['openstack']['cinder']['db']['password'] = node['openstack']['db']['password']
default['openstack']['cinder']['service']['user'] = node['openstack']['service']['user']
default['openstack']['cinder']['service']['password'] = node['openstack']['service']['password']

