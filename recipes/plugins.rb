# frozen_string_literal: true

return if node['jenkins2']['plugins']['install'].empty?

include_recipe 'jenkins2'

jenkins2_plugin node['jenkins2']['plugins']['install'] do
	wait true
	notifies :restart, 'service[jenkins]', :immediately
end
