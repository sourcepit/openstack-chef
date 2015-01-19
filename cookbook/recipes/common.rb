package 'http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm' do
  action :upgrade
end 

package 'http://rdo.fedorapeople.org/openstack-juno/rdo-release-juno.rpm' do
  action :upgrade
end

package 'openstack-selinux' do
  action :upgrade
end