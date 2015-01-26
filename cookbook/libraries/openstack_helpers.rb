module Openstack
  module Helpers
    def determine_virt_type
      cmd = Mixlib::ShellOut.new("egrep -c '(vmx|svm)' /proc/cpuinfo")
      cmd.run_command
      cmd.error!
      cmd.stdout == 0 ? 'qemu' : 'kvm'
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
