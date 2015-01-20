def create_create_db_cmd(db_root_pass, db_name, db_user, db_pass)
  sql = "mysql -u root "
  unless db_root_pass.nil? or db_root_pass.empty?
    sql += "-p" + db_root_pass + " "
  end
  sql += "-e \""
  sql += "CREATE DATABASE " + db_name + ";\n"
  sql += "GRANT ALL PRIVILEGES ON " + db_name + ".* TO '" + db_user + "@\'localhost\' IDENTIFIED BY '" + db_pass + ";\n"
  sql += "GRANT ALL PRIVILEGES ON " + db_name + ".* TO '" + db_user + "@'%' IDENTIFIED BY '" + db_pass + "';"
  sql += "\""
end

execute 'create_db' do
  command create_create_db_cmd(node['mariadb']['root_password'], "keystone", "keystone", "keystone")
  action :run
  notifies :restart, 'service[mariadb]', :immediately
end