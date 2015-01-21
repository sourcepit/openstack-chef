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
  begin
    bash 'create_user' do
      code <<-EOH
        #{get_admin_env(new_resource)}
        keystone --insecure user-create --name #{new_resource.user} --pass #{new_resource.password} 
      EOH
      action :run
      not_if <<-EOH
        #{get_admin_env(new_resource)}
        keystone --insecure user-get #{new_resource.user} 2> /dev/null | grep "+-"
      EOH
    end
  end
end

action :user_role_add do
  begin
    bash 'user_role_add' do
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