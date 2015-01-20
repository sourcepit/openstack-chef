default['network']['if_management'] = 'enp0s8'
default['network']['if_tunnel'] = 'enp0s9'
default['network']['if_external'] = 'enp0s10'
  
default['network']['ip_management'] = '10.0.0.11'
default['network']['ip_tunnel'] = '10.0.1.11'
default['network']['ip_external'] = ''

default['openstack']['repos']  = [
  'http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm',
  'http://rdo.fedorapeople.org/openstack-juno/rdo-release-juno.rpm'
]

default['mariadb']['root_password']  = ''
default['mariadb']['bind_address']  = ''

default['rabbitmq']['bind_address'] = ''
default['rabbitmq']['user'] = ''
default['rabbitmq']['password'] = ''

