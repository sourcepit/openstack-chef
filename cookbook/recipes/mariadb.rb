
#Install client packages
%w{mariadb MySQL-python}.each do |pkg|
  package pkg do
    action :install
  end
end

#Install server packages
package 'mariadb-server' do
  action :install
  notifies :enable, 'service[mariadb]'
  notifies :start, 'service[mariadb]'
  notifies :run, 'execute[change first install root password]'
end

execute 'change first install root password' do
  # Add sensitive true when foodcritic #233 fixed
  command '/usr/bin/mysqladmin -u root password \'' + node['mariadb']['root_password'] + '\''
  action :nothing
  not_if { node['mariadb']['root_password'].empty? }
end

template '/etc/my.cnf' do
  source 'my.cnf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[mariadb]'
end

service 'mariadb' do
  supports restart: true
  action :nothing
end