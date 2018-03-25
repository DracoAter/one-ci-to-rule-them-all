# frozen_string_literal: true

require 'jenkins2'

resource_name :jenkins2_credentials

property :id, String, name_property: true
property :description, String
property :scope, String, equal_to: %w[GLOBAL SYSTEM], default: 'GLOBAL'
# Use either
# - secret
# - filename, content
# - username, password
# - username, private_key, passphrase
property :secret, String, sensitive: true
property :filename, String
property :content, String, sensitive: true
property :username, String
property :password, String, sensitive: true
property :private_key, String, sensitive: true
property :passphrase, String, sensitive: true

property :path, String, default: '', desired_state: false
property :store, String, desired_state: false
property :domain, String, default: '_', desired_state: false
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
	begin
		path.split('/').inject(jc){|acc, elem| acc.job(elem) }.credentials.store(store).
			domain(domain).credential(name).subject
	rescue Jenkins2::NotFoundError
		current_value_does_not_exist!
	end
end

action :create do
	if current_value
		Chef::Log.debug "#{new_resource} No need to create. Credentials already exist."
	else
		converge_by("Create Jenkins Credentials #{new_resource}") do
			Chef::Log.info "#{new_resource}: Creating credentials."
			proxy = new_resource.path.split('/').inject(jc) do |acc, elem|
				acc.job(elem)
			end.credentials.store(store).domain(domain)
			if new_resource.private_key
				proxy.create_ssh(new_resource.to_hash)
			elsif new_resource.secret
				proxy.create_secret_text(new_resource.to_hash)
			elsif new_resource.filename
				proxy.create_secret_file(new_resource.to_hash)
			else
				proxy.create_username_password(new_resource.to_hash)
			end
		end
	end
end

action :delete do
	if current_value
		converge_by("Delete Jenkins Credentials #{new_resource}") do
			Chef::Log.info "#{new_resource}: Deleting credentials."
			new_resource.path.split('/').inject(jc) do |proxy, path|
				proxy.job(path)
			end.credentials.store(store).domain(domain).credential(new_resource.name).delete
		end
	else
		Chef::Log.debug "#{new_resource} No need to delete. Credentials do not exist."
	end
end
