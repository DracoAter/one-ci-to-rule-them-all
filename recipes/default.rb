# frozen_string_literal: true

file '/usr/sbin/policy-rc.d' do
	mode '0755'
	content("#!/bin/sh\nexit 101\n")
end

apt_update

apt_repository 'jenkins' do
	uri node[:jenkins][:repository]
	distribution 'binary/'
	key node[:jenkins][:repository_key]
end

package 'jenkins'

template '/etc/default/jenkins' do
	source 'jenkins-default-config.erb'
	mode 0o644
	notifies :restart, 'service[jenkins]', :immediately
end

service 'jenkins' do
	action %i[start enable]
	supports status: true, restart: true, reload: true
end

# additional packages
package 'git'
