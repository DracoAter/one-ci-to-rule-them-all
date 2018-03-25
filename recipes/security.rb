# frozen_string_literal: true

ruby_block 'enable security' do
	block do
		Jenkins2::Util.try(retries: 10, retry_delay: 10) do
			Jenkins2::Util.wait(max_wait_minutes: 4) do
				jc = Jenkins2.connect(server: 'http://localhost:8080', user: 'admin', key: 'admin')
				jc.connection.get('configureSecurity')
				jc.connection.post(
					'configureSecurity/configure', nil,
					json: node['jenkins2']['security']['configure'].to_json
				)
			end
		end
	end
end

node['jenkins2']['role_strategy'].each do |name, opts|
	jenkins2_role name do
		opts.each do |k, v|
			send(k, v)
		end
	end
end

# Remove anonymous from admin group after we added the right users
jenkins2_role 'admin' do
	action :unassign
	users %w[anonymous]
end
