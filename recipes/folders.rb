# frozen_string_literal: true

node['jenkins2']['folders'].each do |fldr|
	jenkins2_folder fldr
end
