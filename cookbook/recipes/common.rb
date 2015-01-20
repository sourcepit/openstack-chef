node['openstack']['repos'].each do |repo|
  execute 'yum install ' + repo do
    command 'yum reinstall -y ' + repo
    action :run
  end
end

package 'openstack-selinux' do
  action :install
end

template '/etc/hosts' do
  source 'hosts.erb'
end