module Openstack
  module Helpers
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

    def is_db_empty(admin_user, admin_password, db_name)
      result = query(admin_user, admin_password, "SELECT count(*) FROM information_schema.tables WHERE table_type='BASE TABLE' AND table_schema='#{db_name}';")
      result[0]['count(*)'] == '0'
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

    def get_tenant_id(admin_tenant, admin_user, admin_password, auth_uri, tenant)
      cmd = Mixlib::ShellOut.new("keystone --insecure tenant-get #{tenant}")
      cmd.environment = {
        'OS_TENANT_NAME' => admin_tenant,
        'OS_USERNAME' => admin_user,
        'OS_PASSWORD' => admin_password,
        'OS_AUTH_URL' => auth_uri
      }
      cmd.run_command
      cmd.error!
      prettytable_to_array(cmd.stdout)[0]['id']
    end

    def prettytable_to_array(table) # rubocop:disable MethodLength
      ret = []
      return ret if table.nil?
      indicies = []
      (table.split(/$/).map { |x| x.strip }).each do |line|
        unless line.start_with?('+--') || line.empty?
          cols = line.split('|').map { |x| x.strip }
          cols.shift
          if indicies == []
            indicies = cols
            next
          end
          newobj = {}
          cols.each { |val| newobj[indicies[newobj.length]] = val }
          ret.push(newobj)
        end
      end

      # this kinda sucks, but some prettytable data comes
      # as Property Value pairs. If this is the case, then
      # flatten it as expected.
      newobj = {}
      if indicies == ['Property', 'Value']
        ret.each { |x| newobj[x['Property']] = x['Value'] }
        [newobj]
      else
        ret
      end
    end
  end
end

Chef::Recipe.send(:include, ::Openstack::Helpers)
Chef::Resource.send(:include, ::Openstack::Helpers)
Chef::Provider.send(:include, ::Openstack::Helpers)
