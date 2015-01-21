
yum_repository 'rdo-release-juno' do
  description "OpenStack Juno Repository"
  baseurl 'http://repos.fedorapeople.org/repos/openstack/openstack-juno/epel-7/'
  gpgkey 'https://raw.githubusercontent.com/redhat-openstack/rdo-release/juno-1/RPM-GPG-KEY-RDO-Juno'
  action :create
end

yum_repository 'epel-7' do
  description 'Extra Packages for Enterprise Linux'
  mirrorlist 'http://mirrors.fedoraproject.org/mirrorlist?repo=epel-7'
  gpgkey 'http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7'
  action :create
end

package 'openstack-selinux' do
  action :install
end

template '/etc/hosts' do
  source 'hosts.erb'
end