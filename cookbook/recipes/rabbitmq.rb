package 'rabbitmq-server' do
  action :upgrade
  notifies :enable, 'service[rabbitmq-server]', :immediately
  notifies :start, 'service[rabbitmq-server]', :immediately
  notifies :run, 'execute[init user]', :immediately
end

execute 'init user' do
  # Add sensitive true when foodcritic #233 fixed
  command 'rabbitmqctl delete_user guest &&\
    rabbitmqctl add_user ' + node['rabbitmq']['user'] + ' ' + node['rabbitmq']['password'] + ' &&\
    rabbitmqctl set_permissions -p / ' + node['rabbitmq']['user'] + ' ".*" ".*" ".*"'
  action :nothing
  not_if { node['rabbitmq']['user'].empty? }
end

template '/etc/rabbitmq/rabbitmq-env.conf' do
  source 'rabbitmq-env.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[rabbitmq-server]', :immediately
end

service 'rabbitmq-server' do
  supports restart: true
  action :nothing
end