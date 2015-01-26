action :add_br do

  cmd = Mixlib::ShellOut.new("ovs-vsctl br-exists #{new_resource.bridge}")
  cmd.run_command
  cmd.error!

  if (cmd.stdout.empty?)
    cmd = Mixlib::ShellOut.new("ovs-vsctl add-br #{new_resource.bridge}")
    cmd.run_command
    cmd.error!
    new_resource.updated_by_last_action(true)
  end

end

action :add_port do

  cmd = Mixlib::ShellOut.new("ovs-vsctl list-ports #{new_resource.bridge} | grep #{new_resource.port}")
  cmd.run_command
  cmd.error!

  if (cmd.stdout.empty?)
    cmd = Mixlib::ShellOut.new("ovs-vsctl add-port #{new_resource.bridge} #{new_resource.port}")
    cmd.run_command
    cmd.error!
    new_resource.updated_by_last_action(true)
  end

end