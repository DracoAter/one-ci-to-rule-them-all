require 'jenkins2'
require 'rexml/document'

resource_name :jenkins2_pipeline

property :repository_url, String, required: true
property :script, String, default: 'Jenkinsfile', required: true
property :credentials_id, String
property :multibranch, [true, false], default: false
property :path, String, desired_state: false, default: ''
property :connection, Hash, desired_state: false,
	default: { server: 'http://localhost:8080', user: 'admin', key: 'admin' }

include JenkinsHelper

PIPELINE_XML = '<flow-definition plugin="workflow-job@2.17"><description/>
<keepDependencies>false</keepDependencies><properties/>
<definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition"
plugin="workflow-cps@2.45">
<scm class="hudson.plugins.git.GitSCM" plugin="git@3.8.0">
<configVersion>2</configVersion><userRemoteConfigs><hudson.plugins.git.UserRemoteConfig>
<url>%<repository_url>s</url><credentialsId>%<credentials_id>s</credentialsId>
</hudson.plugins.git.UserRemoteConfig></userRemoteConfigs><branches>
<hudson.plugins.git.BranchSpec><name>*/master</name></hudson.plugins.git.BranchSpec>
</branches><doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
<submoduleCfg class="list"/><extensions/></scm><scriptPath>%<script>s</scriptPath>
<lightweight>true</lightweight></definition><triggers/><disabled>false</disabled>
</flow-definition>'.freeze

MULTIBRANCH_PIPELINE_XML = '<org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject plugin="workflow-multibranch@2.17">
<sources class="jenkins.branch.MultiBranchProject$BranchSourceList" plugin="branch-api@2.0.18">
<data><jenkins.branch.BranchSource>
<source class="jenkins.plugins.git.GitSCMSource" plugin="git@3.8.0">
<remote>%<repository_url>s</remote>
<credentialsId>%<credentials_id>s</credentialsId><traits>
<jenkins.plugins.git.traits.BranchDiscoveryTrait/></traits></source>
<strategy class="jenkins.branch.DefaultBranchPropertyStrategy"><properties class="empty-list"/>
</strategy></jenkins.branch.BranchSource></data>
<owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
</sources><factory class="org.jenkinsci.plugins.workflow.multibranch.WorkflowBranchProjectFactory">
<owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
<scriptPath>%<script>s</scriptPath></factory>
</org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject>'.freeze

load_current_value do
  ensure_listening
  begin
    xml_root = REXML::Document.new(
      path.split('/').inject(jc) { |acc, elem| acc.job(elem) }.job(name).config_xml
    ).root
    multibranch xml_root.name.include? 'multibranch'
    if multibranch
      repository_url xml_root.text('//source/remote').to_s
      script xml_root.text('//scriptPath')
      credentials_id xml_root.text('//source/credentialsId')
    else
      repository_url xml_root.text('//url')
      script xml_root.text('//scriptPath')
      credentials_id xml_root.text('//credentialsId')
    end
  rescue Jenkins2::NotFoundError
    current_value_does_not_exist!
  end
end

action :create do
  if current_value
    Chef::Log.debug "#{new_resource} No need to create. Pipeline already exists."
    run_action :update
  else
    converge_by("Create Jenkins Pipeline #{new_resource.name}") do
      Chef::Log.info "#{new_resource}: Creating Pipeline."
      new_resource.path.split('/').inject(jc) do |acc, elem|
        acc.job(elem)
      end.job(new_resource.name).create(format(new_resource.template, new_resource.to_hash))
    end
  end
end

action :update do
  if current_value
    converge_if_changed :multibranch do
      run_action :delete
      run_action :create
    end
    converge_if_changed do
      converge_by("Update jenkins pipeline #{new_resource.name}") do
        Chef::Log.info "#{new_resource}: Updating pipeline."
        new_resource.path.split('/').inject(jc) do |acc, elem|
          acc.job(elem)
        end.job(new_resource.name).update(format(template, new_resource.to_hash))
      end
    end
  else
    Chef::Log.debug "#{new_resource} Pipeline does not exist. Nothing to update."
  end
end

action :delete do
  if folder_exist?
    converge_by("Delete Jenkins Pipeline #{new_resource.name}") do
      Chef::Log.info "#{new_resource}: Deleting Pipeline."
      new_resource.path.split('/').inject(jc) do |acc, elem|
        acc.job(elem)
      end.job(new_resource.name).delete
    end
  else
    Chef::Log.debug "#{new_resource} No need to delete. Pipeline does not exist."
  end
end

def template
  multibranch ? MULTIBRANCH_PIPELINE_XML : PIPELINE_XML
end
