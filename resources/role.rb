require 'jenkins2'

resource_name :jenkins2_role

property :permissions, Array, default: []
property :pattern, String
property :users, Array, default: [], coerce: proc { |m| m.sort }

property :type, %w(globalRoles projectRoles slaveRoles), default: 'globalRoles', desired_state: false
property :connection, Hash, desired_state: false,
	default: { server: 'http://localhost:8080', user: 'admin', key: 'admin' }

include JenkinsHelper

action_class do
  def do_assign(users)
    users.each do |user|
      jc.roles.assign(role: name, type: type, rsuser: user)
    end
  end

  def do_unassign(users)
    users.each do |user|
      jc.roles.assign(role: name, type: type, rsuser: user)
    end
  end
end

load_current_value do
  ensure_listening
  case type
  when 'globalRoles'
    existing_roles = jc.roles.list
    if existing_roles.key? name.to_sym
      users jc.roles.list[name.to_sym].sort
    else
      current_value_does_not_exist!
    end
  else
    current_value_does_not_exist!
  end
end

action :create do
  converge_if_changed do
    jc.roles.create(role: new_resource.name, type: new_resource.type,
                    permissions: new_resource.permissions, pattern: new_resource.pattern)
  end
  converge_if_changed :users do
    if current_value
      do_assign(new_resource.users - current_value.users)
    else
      do_assign(new_resource.users)
    end
  end
end

action :delete do
  if current_value
    converge_by("delete #{new_resource.identity}") do
      jc.roles.delete(role: new_resource.name, type: new_resource.type)
    end
  end
end

action :unassign do
  if current_value
    converge_if_changed :users do
      do_unassign(new_resource.users & current_value.users)
    end
  elsif new_resource.type != 'globalRoles'
    converge_if_changed :users do
      do_unassign(new_resource.users)
    end
  else
    Chef::Log.debug "#{new_resource} No need to unassign from role. Role does not exist."
  end
end
