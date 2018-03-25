# frozen_string_literal: true

include_recipe 'jenkins2::folders'

node['jenkins2']['pipelines'].each do |ppln, opts|
	jenkins2_pipeline ppln do
		opts.each do |k, v|
			send(k, v)
		end
	end
end
