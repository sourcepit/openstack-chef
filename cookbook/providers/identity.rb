def get_admin_env(resource)
  if (resource.admin_token.nil? or resource.admin_token.empty?)
    {
      'OS_TENANT_NAME' => resource.admin_tenant,
      'OS_USERNAME' => resource.admin_user,
      'OS_PASSWORD' => resource.admin_password,
      'OS_AUTH_URL' => resource.auth_uri
    }
  else
    {
      'OS_SERVICE_ENDPOINT' => resource.auth_uri,
      'OS_SERVICE_TOKEN' => resource.admin_token,
    }
  end
end

def get_user_env(resource)
  if (resource.admin_token.nil? or resource.admin_token.empty?)
    {
      'OS_TENANT_NAME' => resource.tenant_name ,
      'OS_USERNAME' => resource.user,
      'OS_PASSWORD' => resource.password,
      'OS_AUTH_URL' => resource.auth_uri
    }
  else
    {
      'OS_SERVICE_ENDPOINT' => resource.auth_uri,
      'OS_SERVICE_TOKEN' => resource.admin_token,
    }
  end
end

action :tenant_create do

  cmd = Mixlib::ShellOut.new("keystone --insecure tenant-get #{new_resource.tenant_name}")
  cmd.environment = get_admin_env(new_resource)
  cmd.run_command

  exists = !cmd.stdout.empty?

  if (exists)
    new_resource.updated_by_last_action(false)
  else
    cmd = Mixlib::ShellOut.new("keystone --insecure tenant-create --name #{new_resource.tenant_name } --description \"#{new_resource.tenant_description}\"")
    cmd.environment = get_admin_env(new_resource)
    cmd.run_command
    cmd.error!
    new_resource.updated_by_last_action(true)
  end

end

action :user_create do

  cmd = Mixlib::ShellOut.new("keystone --insecure user-get #{new_resource.user}")
  cmd.environment = get_admin_env(new_resource)
  cmd.run_command

  exists = !cmd.stdout.empty?

  if (exists)
    new_resource.updated_by_last_action(false)
  else
    cmd = Mixlib::ShellOut.new("keystone --insecure user-create --name #{new_resource.user} --pass #{new_resource.password}")
    cmd.environment = get_admin_env(new_resource)
    cmd.run_command
    cmd.error!
    new_resource.updated_by_last_action(true)
  end

end

action :role_create do

  cmd = Mixlib::ShellOut.new("keystone --insecure role-get #{new_resource.role}")
  cmd.environment = get_admin_env(new_resource)
  cmd.run_command

  exists = !cmd.stdout.empty?

  if (exists)
    new_resource.updated_by_last_action(false)
  else
    cmd = Mixlib::ShellOut.new("keystone --insecure role-create --name #{new_resource.role}")
    cmd.environment = get_admin_env(new_resource)
    cmd.run_command
    cmd.error!
    new_resource.updated_by_last_action(true)
  end

end

action :user_role_add do

  cmd = Mixlib::ShellOut.new("keystone --insecure user-role-list --user #{new_resource.user} --tenant #{new_resource.tenant_name} | grep \" #{new_resource.role} \"")
  cmd.environment = get_admin_env(new_resource)

  cmd.run_command

  exists = !cmd.stdout.empty?

  if (exists)
    new_resource.updated_by_last_action(false)
  else
    cmd = Mixlib::ShellOut.new("keystone --insecure user-role-add --user #{new_resource.user} --tenant #{new_resource.tenant_name } --role #{new_resource.role}")
    cmd.environment = get_admin_env(new_resource)
    cmd.run_command
    cmd.error!
    new_resource.updated_by_last_action(true)
  end

end

action :service_create do

  cmd = Mixlib::ShellOut.new("keystone --insecure service-get #{new_resource.service_name}")
  cmd.environment = get_user_env(new_resource)
  cmd.run_command

  exists = !cmd.stdout.empty?

  if (exists)
    new_resource.updated_by_last_action(false)
  else
    cmd = Mixlib::ShellOut.new("keystone --insecure service-create --name #{new_resource.service_name} --type #{new_resource.service_type} --description \"#{new_resource.service_description}\"")
    cmd.environment = get_admin_env(new_resource)
    cmd.run_command
    cmd.error!
    new_resource.updated_by_last_action(true)
  end

end

action :endpoint_create do

  cmd = Mixlib::ShellOut.new("keystone --insecure endpoint-get --service #{new_resource.service_type}")
  cmd.environment = get_user_env(new_resource)
  cmd.run_command

  exists = !cmd.stdout.empty?

  if (exists)
    new_resource.updated_by_last_action(false)
  else
    endpoint_admin_url = (new_resource.endpoint_admin_url.nil?) ? new_resource.endpoint_url : new_resource.endpoint_admin_url
    cmdStr = <<-eos
      keystone endpoint-create \
        --service-id $(keystone service-list | awk '/ #{new_resource.service_type} / {print $2}') \
        --publicurl #{new_resource.endpoint_url} \
        --internalurl #{new_resource.endpoint_url} \
        --adminurl #{endpoint_admin_url} \
        --region #{new_resource.endpoint_region}
    eos
    cmd = Mixlib::ShellOut.new(cmdStr)
    cmd.environment = get_admin_env(new_resource)
    cmd.run_command
    cmd.error!
    new_resource.updated_by_last_action(true)
  end

end
