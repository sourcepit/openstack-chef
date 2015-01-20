module Openstack
  module Helpers
    def create_create_db_cmd(db_root_pass, db_name, db_user, db_pass)
      sql = "mysql -u root "
      unless db_root_pass.nil? or db_root_pass.empty?
        sql += "-p" + db_root_pass + " "
      end
      sql += "-e \""
      sql += "CREATE DATABASE IF NOT EXISTS " + db_name + ";\n"
      sql += "GRANT ALL PRIVILEGES ON " + db_name + ".* TO '" + db_user + "'@\'localhost\' IDENTIFIED BY '" + db_pass + "';\n"
      sql += "GRANT ALL PRIVILEGES ON " + db_name + ".* TO '" + db_user + "'@'%' IDENTIFIED BY '" + db_pass + "';"
      sql += "\""
    end

    def create_db_url(host, database, user, password)
      url = "mysql://"
      unless user.nil? or user.empty?
        url += user
        unless password.nil? or password.empty?
          url += ":" + password
        end
        url += "@"
      end
      if host.nil? or host.empty?
        url += "localhost"
      else
        url += host
      end
      unless database.nil? or database.empty?
        url += "/" + database
      end
    end
  end
end

Chef::Recipe.send(:include, ::Openstack::Helpers)
Chef::Resource.send(:include, ::Openstack::Helpers)
Chef::Provider.send(:include, ::Openstack::Helpers)
