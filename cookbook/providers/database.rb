def mysql_exec(admin_user, admin_password, cmd)
  sql = 'mysql -u ' + admin_user + ' '
  unless admin_password.nil? or admin_password.empty?
    sql += '-p' + admin_password + ' '
  end
  sql += '--table -e "'+ cmd + '"'
end

def query(admin_user, admin_password, query)
  cmd = Mixlib::ShellOut.new(mysql_exec(admin_user, admin_password, query))
  cmd.run_command
  cmd.error!
  prettytable_to_array(cmd.stdout)
end

action :create_db do
  result = query(new_resource.admin_user, new_resource.admin_password, "SELECT schema_name FROM information_schema.schemata WHERE schema_name='#{new_resource.db_name}';")
  if (result.empty?)
    cmd = Mixlib::ShellOut.new(mysql_exec(new_resource.admin_user, new_resource.admin_password, "CREATE DATABASE #{new_resource.db_name};"))
    cmd.run_command
    cmd.error!
    new_resource.updated_by_last_action(true)
  else
    new_resource.updated_by_last_action(false)
  end
end

action :grant_privileges do
  new_resource.updated_by_last_action(false)

  new_resource.hosts.each do |host|
    result = query(new_resource.admin_user, new_resource.admin_password, "select count(*) from mysql.db where db='#{new_resource.db_name}' and user='#{new_resource.user}' and host='#{host}';")
    if (result[0]['count(*)'] == '0')
      cmd = Mixlib::ShellOut.new(mysql_exec(new_resource.admin_user, new_resource.admin_password, "GRANT ALL PRIVILEGES ON #{new_resource.db_name}.* TO '#{new_resource.user}'@'#{new_resource.host}' IDENTIFIED BY '#{new_resource.passwords}';"))
      cmd.run_command
      cmd.error!
      new_resource.updated_by_last_action(true)
    end
  end
end