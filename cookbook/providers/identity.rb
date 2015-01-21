def get_env(resource)
  <<-EOH
    export OS_TENANT_NAME=#{resource.admin_tenant}
    export OS_USERNAME=#{resource.admin_user}
    export OS_PASSWORD=#{resource.admin_password}
    export OS_AUTH_URL=#{resource.auth_uri}
  EOH
end

action :create_user do
  begin
    bash 'create service endpoint' do
      code <<-EOH
        #{get_env(new_resource)}
        keystone user-create --name #{new_resource.user} --pass #{new_resource.password} 
      EOH
      action :run
      not_if <<-EOH
        #{get_env(new_resource)}
        keystone user-get #{new_resource.user} 2> /dev/null | grep "+-"
      EOH
    end
  end
end