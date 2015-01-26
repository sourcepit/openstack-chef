action :add_br do

  cmd = Mixlib::ShellOut.new("ovs-vsctl br-exists #{new_resource.bridge}")
  cmd.valid_exit_codes = [0,2]
  cmd.run_command
  cmd.error!

  if (cmd.exitstatus == 2)
    cmd = Mixlib::ShellOut.new("ovs-vsctl add-br #{new_resource.bridge}")
    cmd.run_command
    cmd.error!
    new_resource.updated_by_last_action(true)
  end

end

action :add_port do

  check = Mixlib::ShellOut.new("ovs-vsctl list-ports #{new_resource.bridge} | grep #{new_resource.port}")
  check.run_command

  bridge_empty = check.exitstatus == 1 && check.stderr.empty? && check.stdout.empty?
  port_exists = check.exitstatus == 0 && !check.stdout.empty?

  if (bridge_empty or !port_exists)
    cmd = Mixlib::ShellOut.new("ovs-vsctl add-port #{new_resource.bridge} #{new_resource.port}")
    cmd.run_command
    cmd.error!
    new_resource.updated_by_last_action(true)
  else
    check.error!
  end

end
