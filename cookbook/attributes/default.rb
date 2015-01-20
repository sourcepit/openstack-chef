default['network']['if_management'] = 'enp0s8'
default['network']['if_tunnel'] = 'enp0s9'
default['network']['if_external'] = 'enp0s10'
  
default['network']['ip_management'] = '10.0.0.11'
default['network']['ip_tunnel'] = '10.0.1.11'
default['network']['ip_external'] = ''
  
default['network']['hosts_management'] = %w(controller.bosch-si.com controller)

default['openstack']['repos']  = [
  'http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm',
  'http://rdo.fedorapeople.org/openstack-juno/rdo-release-juno.rpm'
]

default['mariadb']['root_password']  = ''
default['mariadb']['bind_address']  = ''
default['mariadb']['host']  = node['mariadb']['bind_address']

default['rabbitmq']['bind_address'] = ''
default['rabbitmq']['user'] = ''
default['rabbitmq']['password'] = ''

default['openstack']['logging']['verbose'] = 'false'
default['openstack']['logging']['debug'] = 'false'
  
default['openstack']['controller']['ip'] = node['network']['ip_management']
default['openstack']['controller']['hosts'] = node['network']['hosts_management']
default['openstack']['controller']['host'] = node['openstack']['controller']['hosts'][0]
  
default['openstack']['admin']['user'] = 'admin'
default['openstack']['admin']['password'] = 'secret'
default['openstack']['admin']['email'] = 'admin@' + node['openstack']['controller']['host'] 
  
default['openstack']['db']['user'] = 'admin'
default['openstack']['db']['password'] = 'secret'
default['openstack']['service']['password'] = 'secret'
    
default['openstack']['identity']['db']['user'] = node['openstack']['db']['user']
default['openstack']['identity']['db']['password'] = node['openstack']['db']['password']
default['openstack']['identity']['admin_token'] = '17986b3c37e2b95dcf03'
  
default['openstack']['image']['db']['user'] = node['openstack']['db']['user']
default['openstack']['image']['db']['password'] = node['openstack']['db']['password']
default['openstack']['image']['service']['password'] = node['openstack']['service']['password']

