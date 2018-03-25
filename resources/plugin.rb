require 'jenkins2'

resource_name :jenkins2_plugin

property :name, Array, name_property: true
property :wait, [false, true], default: false, desired_state: false
property :connection, Hash, desired_state: false,
	default: { server: 'http://localhost:8080', user: 'admin', key: 'admin' }

include JenkinsHelper

action :install do
  if plugins_installed?
    Chef::Log.debug "#{new_resource} No need to install. Plugins already installed."
  else
    converge_by("Install jenkins plugins #{new_resource.name}") do
      Chef::Log.info "#{new_resource}: Installing plugins."
      Jenkins2::Util.try(retries: 24) do # 2 minutes
        jc.connection.post('pluginManager/checkUpdatesServer')
      end
      jc.plugins.install(new_resource.name)
    end
    if new_resource.wait
      converge_by("Wait jenkins plugins to activate #{new_resource.name}") do
        Chef::Log.info "#{new_resource}: Waiting for plugins."
        Jenkins2::Util.wait(max_wait_minutes: 10) do
          plugins_installed?
        end
      end
    end
  end
end

action :uninstall do
  if plugins_installed?
    converge_by("Uninstall jenkins plugin #{new_resource.name}") do
      Chef::Log.info "#{new_resource}: Uninstalling plugin."
      jc.plugins.plugin(new_resource.name).uninstall
    end
  else
    Chef::Log.debug "#{new_resource} No need to uninstall. Plugin already uninstalled."
  end
end

def plugins_installed?
  ensure_listening
  jc.plugins(depth: 1).plugins.select do |plg|
    name.include?(plg.shortName) && plg.active
  end.size == name.size
end

