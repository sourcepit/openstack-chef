%w(openstack-nova-compute sysfsutils).each do |pkg|
  package pkg do
    action :install
  end
end

include_recipe 'openstack::internal_nova-conf'