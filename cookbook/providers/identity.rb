def get_admin_env(resource)
  {
    'OS_TENANT_NAME' => resource.admin_tenant,
    'OS_USERNAME' => resource.admin_user,
    'OS_PASSWORD' => resource.admin_password,
    'OS_AUTH_URL' => resource.auth_uri
  }
end

def get_user_env(resource)
  {
    'OS_TENANT_NAME' => resource.tenant,
    'OS_USERNAME' => resource.user,
    'OS_PASSWORD' => resource.password,
    'OS_AUTH_URL' => resource.auth_uri
  }
end

action :create_user do

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

action :user_role_add do

  cmd = Mixlib::ShellOut.new("keystone --insecure user-role-list | grep \" #{new_resource.role} \"")
  cmd.environment = get_user_env(new_resource)
  cmd.run_command

  exists = !cmd.stdout.empty?

  if (exists)
    new_resource.updated_by_last_action(false)
  else
    cmd = Mixlib::ShellOut.new("keystone --insecure user-role-add --user #{new_resource.user} --tenant #{new_resource.tenant} --role #{new_resource.role}")
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
    cmd = Mixlib::ShellOut.new("keystone --insecure service-create --name #{new_resource.service_name} --type #{new_resource.service_type} --description #{new_resource.service_description}")
    cmd.environment = get_admin_env(new_resource)
    cmd.run_command
    cmd.error!
    new_resource.updated_by_last_action(true)
  end

end

action :endpoint_create do

  cmd = Mixlib::ShellOut.new("keystone --insecure service-get #{new_resource.service_name}")
  cmd.environment = get_user_env(new_resource)
  cmd.run_command

  exists = !cmd.stdout.empty?

  if (exists)
    new_resource.updated_by_last_action(false)
  else
    cmdStr <<-eos
      keystone endpoint-create \
        --service-id $(keystone service-list | awk '/ #{new_resource.service_type} / {print $2}') \
        --publicurl #{new_resource.endpoint_url} \
        --internalurl #{new_resource.endpoint_url} \
        --adminurl #{new_resource.endpoint_url} \
        --region #{new_resource.endpoint_region}
    eos
    cmd = Mixlib::ShellOut.new(cmdStr)
    cmd.environment = get_admin_env(new_resource)
    cmd.run_command
    cmd.error!
    new_resource.updated_by_last_action(true)
  end

end
