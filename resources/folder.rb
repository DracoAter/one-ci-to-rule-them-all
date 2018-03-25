require 'jenkins2'

resource_name :jenkins2_folder

property :path, String, desired_state: false
property :connection, Hash, desired_state: false,
	default: { server: 'http://localhost:8080', user: 'admin', key: 'admin' }

include JenkinsHelper

FOLDER_XML = %(<com.cloudbees.hudson.plugins.folder.Folder plugin="cloudbees-folder@6.3">
  </com.cloudbees.hudson.plugins.folder.Folder>).freeze

load_current_value do
  ensure_listening
  begin
    path.split('/').inject(jc) { |acc, elem| acc.job(elem) }.job(name).subject
  rescue Jenkins2::NotFoundError
    current_value_does_not_exist!
  end
end

action :create do
  if current_value
    Chef::Log.debug "#{new_resource} No need to create. Folder already exists."
  else
    converge_by("Create Jenkins Folder #{new_resource.name}") do
      Chef::Log.info "#{new_resource}: Creating folder."
      new_resource.path.split('/').inject(jc) do |acc, elem|
        acc.job(elem)
      end.job(new_resource.name).create(FOLDER_XML)
    end
  end
end

action :delete do
  if current_value
    converge_by("Delete Jenkins Folder #{new_resource.name}") do
      Chef::Log.info "#{new_resource}: Deleting folder."
      new_resource.path.split('/').inject(jc) do |acc, elem|
        acc.job(elem)
      end.job(new_resource.name).delete
    end
  else
    Chef::Log.debug "#{new_resource} No need to delete. Folder does not exist."
  end
end
