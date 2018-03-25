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
	mode 0644
	notifies :restart, 'service[jenkins]', :immediately
end

service 'jenkins' do
	action [:start, :enable]
	supports status: true, restart: true, reload: true
end
