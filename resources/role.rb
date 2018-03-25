require 'jenkins2'

resource_name :jenkins2_role

property :permissions, Array, default: []
property :pattern, String
property :users, Array, default: [], coerce: proc { |m| m.sort }

property :type, %w(globalRoles projectRoles slaveRoles), default: 'globalRoles', desired_state: false
property :connection, Hash, desired_state: false,
	default: { server: 'http://localhost:8080', user: 'admin', key: 'admin' }

include JenkinsHelper

declare_action_class.class_eval do
  def whyrun_supported?
    true
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
  if current_value
    Chef::Log.debug "#{new_resource} No need to create. Role already exists."
  else
    converge_by("Create Jenkins Role #{new_resource.name}") do
      Chef::Log.info "#{new_resource}: Creating role."
      jc.roles.create(role: new_resource.name, type: new_resource.type,
                      permissions: new_resource.permissions, pattern: new_resource.pattern)
    end
  end
  run_action :assign unless new_resource.users.empty?
end

action :delete do
  if current_value
    converge_by("Delete Jenkins Role #{new_resource.name}") do
      Chef::Log.info "#{new_resource}: Deleting role."
      jc.roles.delete(role: new_resource.name, type: new_resource.type)
    end
  else
    Chef::Log.debug "#{new_resource} No need to delete. Role does not exist."
  end
end

action :assign do
  if current_value
    converge_if_changed :users do
      (new_resource.users - current_value.users).each do |user|
        converge_by("Assign Jenkins Role #{new_resource.name} to user #{user}") do
          Chef::Log.info "#{new_resource}: Assigning role to user #{user}."
          jc.roles.assign(role: new_resource.name, type: new_resource.type, rsuser: user)
        end
      end
    end
  elsif new_resource.type != 'globalRoles'
    new_resource.users.each do |user|
      converge_by("Assign Jenkins Role #{new_resource.name} to user #{user}") do
        Chef::Log.info "#{new_resource}: Assigning role to user #{user}."
        jc.roles.assign(role: new_resource.name, type: new_resource.type, rsuser: user)
      end
    end
  else
    Chef::Log.debug "#{new_resource} Cannot assign users. Role does not exist."
  end
end

action :unassign do
  if current_value
    new_resource.users.select { |u| current_value.users.include? u }.each do |user|
      converge_by("Unassign Jenkins Role #{new_resource.name} from user #{user}") do
        Chef::Log.info "#{new_resource}: Unassigning role from user #{user}."
        jc.roles.unassign(role: new_resource.name, type: new_resource.type, rsuser: user)
      end
    end
  else
    Chef::Log.debug "#{new_resource} No need to unassign from role. Role does not exist."
  end
end
