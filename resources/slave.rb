# frozen_string_literal: true

require 'jenkins2'
require 'rexml/document'

resource_name :jenkins2_slave

property :remote_fs, String
property :host, String
property :description, String
property :executors, Integer
property :credentials_id, String
property :labels, Array, default: [], coerce: proc{|m| m.sort }
property :port, Integer, default: 22
property :connection, Hash, desired_state: false,
	default: { server: 'http://localhost:8080', user: 'admin', key: 'admin' }

include JenkinsHelper

declare_action_class.class_eval do
	def whyrun_supported?
		true
	end
end

SSH_SLAVE_XML = '<slave><name>%<name>s</name><description>%<description>s</description>
<remoteFS>%<remote_fs>s</remoteFS><numExecutors>%<executors>s</numExecutors>
<launcher class="hudson.plugins.sshslaves.SSHLauncher" plugin="ssh-slaves@1.26">
<host>%<host>s</host><port>%<port>i</port><credentialsId>%<credentials_id>s</credentialsId>
<sshHostKeyVerificationStrategy
class="hudson.plugins.sshslaves.verifiers.NonVerifyingKeyVerificationStrategy"/>
</launcher><label>%<label>s</label></slave>'

load_current_value do
	ensure_listening
	begin
		xml_root = REXML::Document.new(jc.computer(name).config_xml).root
		description xml_root.text('description')
		remote_fs xml_root.text('remoteFS')
		host xml_root.text('launcher/host')
		port xml_root.text('launcher/port').to_i
		executors xml_root.text('numExecutors').to_i
		credentials_id xml_root.text('launcher/credentialsId')
		labels xml_root.text('label').to_s.split(' ').sort
	rescue Jenkins2::NotFoundError
		current_value_does_not_exist!
	end
end

action :create do
	if current_value
		Chef::Log.debug "#{new_resource} No need to create. Slave already exists."
	else
		converge_by("Create jenkins slave #{new_resource.name}") do
			Chef::Log.info "#{new_resource}: Creating slave."
			jc.computer(new_resource.name).create
		end
	end
	run_action :update
end

action :update do
	if current_value
		converge_if_changed do
			converge_by("Update jenkins slave #{new_resource.name}") do
				Chef::Log.info "#{new_resource}: Updating slave."
				jc.computer(new_resource.name).update(format(SSH_SLAVE_XML,
					label: new_resource.labels.join(' '), **new_resource.to_hash))
			end
		end
	else
		Chef::Log.debug "#{new_resource} Slave does not exist. Nothing to update."
	end
end

action :delete do
	if current_value
		converge_by("Delete Jenkins slave #{new_resource.name}") do
			Chef::Log.info "#{new_resource}: Deleting slave."
			jc.computer(new_resource.name).delete
		end
	else
		Chef::Log.debug "#{new_resource} No need to delete. Slave already deleted."
	end
end
