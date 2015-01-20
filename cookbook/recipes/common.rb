node['openstack']['repos'].each do |repo|
  execute 'yum install ' + repo do
    command 'yum reinstall -y ' + repo
    action :run
  end
end

package 'openstack-selinux' do
  action :upgrade
end