node['openstack']['repos'].each do |repo|
  execute 'install epel repo' do
    command 'yum reinstall -y ' + repo
    action :run
  end
end

package 'openstack-selinux' do
  action :upgrade
end