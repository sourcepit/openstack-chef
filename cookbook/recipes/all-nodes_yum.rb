
include_recipe 'yum-epel::default'

yum_repository 'rdo-release-juno' do
  description "OpenStack Juno Repository"
  baseurl 'http://repos.fedorapeople.org/repos/openstack/openstack-juno/epel-7/'
  gpgkey 'https://raw.githubusercontent.com/redhat-openstack/rdo-release/juno-1/RPM-GPG-KEY-RDO-Juno'
  action :create
end

package 'openstack-selinux' do
  action :install
end
