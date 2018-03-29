require 'jenkins2'

resource_name :jenkins2_folder

property :path, String, name_property: true, identity: true

include JenkinsHelper

FOLDER_XML = '<com.cloudbees.hudson.plugins.folder.Folder plugin="cloudbees-folder@6.3" />'.freeze

load_current_value do
  ensure_listening
  begin
    folder_proxy.subject
  rescue Jenkins2::NotFoundError
    current_value_does_not_exist!
  end
end

action :create do
  converge_if_changed do
    folder_proxy.create(FOLDER_XML)
  end
end

action :delete do
  if current_value
    converge_by("delete #{new_resource.identity}") do
      folder_proxy.delete
    end
  end
end

def folder_proxy
  @folder_proxy ||= path.split('/').inject(jc) { |acc, elem| acc.job(elem) }
end
