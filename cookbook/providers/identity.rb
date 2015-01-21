def get_admin_env(resource)
  <<-EOH
    export OS_TENANT_NAME=#{resource.admin_tenant}
    export OS_USERNAME=#{resource.admin_user}
    export OS_PASSWORD=#{resource.admin_password}
    export OS_AUTH_URL=#{resource.auth_uri}
  EOH
end

def get_user_env(resource)
  <<-EOH
    export OS_TENANT_NAME=#{resource.tenant}
    export OS_USERNAME=#{resource.user}
    export OS_PASSWORD=#{resource.password}
    export OS_AUTH_URL=#{resource.auth_uri}
  EOH
end

action :create_user do

  b = bash 'keystone user-create' do
    code <<-EOH
        #{get_admin_env(new_resource)}
        keystone --insecure user-create --name #{new_resource.user} --pass #{new_resource.password} 
    EOH
    action :run
    notifies :run, 'ruby_block[notify updated]', :immediately
    not_if <<-EOH
        #{get_admin_env(new_resource)}
        keystone --insecure user-get #{new_resource.user} 2> /dev/null
    EOH
  end

  new_resource.updated_by_last_action(b.updated_by_last_action?)

end

action :user_role_add do
  begin
    bash 'keystone user-role-add' do
      code <<-EOH
        #{get_admin_env(new_resource)}
        keystone --insecure user-role-add --user #{new_resource.user} --tenant #{new_resource.tenant} --role #{new_resource.role}
      EOH
      action :run
      not_if <<-EOH
        #{get_user_env(new_resource)}
        keystone --insecure user-role-list 2> /dev/null | grep " #{new_resource.role} "
      EOH
    end
  end
end

action :service_create do
  begin
    bash 'keystone service-create' do
      code <<-EOH
        #{get_admin_env(new_resource)}
        keystone --insecure service-create --name #{new_resource.service_name} --type #{new_resource.service_type} --description #{new_resource.service_description}
      EOH
      action :run
      not_if <<-EOH
        #{get_admin_env(new_resource)}
        keystone --insecure service-get #{new_resource.service_name} 2> /dev/null
      EOH
    end
  end
end

action :endpoint_create do
  begin
    bash 'keystone endpoint-create' do
      code <<-EOH
        #{get_admin_env(new_resource)}
        keystone endpoint-create \
          --service-id $(keystone service-list | awk '/ #{new_resource.service_type} / {print $2}') \
          --publicurl #{new_resource.endpoint_url} \
          --internalurl #{new_resource.endpoint_url} \
          --adminurl #{new_resource.endpoint_url} \
          --region #{new_resource.endpoint_region}
      EOH
      action :run
      not_if <<-EOH
        #{get_admin_env(new_resource)}
        keystone --insecure endpoint-get --service #{new_resource.service_type} 2> /dev/null
      EOH
    end
  end
end
