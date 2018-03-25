# frozen_string_literal: true

jenkins_data = data_bag_item('jenkins2', 'secrets')

return unless jenkins_data['credentials']

include_recipe 'jenkins2::folders'

jenkins_data['credentials'].each do |name, opts|
	jenkins2_credentials name do
		opts.each do |k, v|
			send(k, v)
		end
	end
end
