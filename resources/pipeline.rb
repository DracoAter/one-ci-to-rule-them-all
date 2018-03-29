# frozen_string_literal: true

require 'jenkins2'
require 'rexml/document'

resource_name :jenkins2_pipeline

property :path, String, name_property: true, identity: true
property :repository_url, String
property :script_path, String, default: 'Jenkinsfile'
property :credentials_id, String
property :multibranch, [true, false], default: false
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
<submoduleCfg class="list"/><extensions/></scm><scriptPath>%<script_path>s</scriptPath>
<lightweight>true</lightweight></definition><triggers/><disabled>false</disabled>
</flow-definition>'

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
<scriptPath>%<script_path>s</scriptPath></factory>
</org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject>'

action_class do
	def template
		multibranch ? MULTIBRANCH_PIPELINE_XML : PIPELINE_XML
	end

	def do_delete
		job_proxy.delete
	end

	def do_create(method_name)
		job_proxy.__send__(method_name, format(template, to_hash))
	end
end

load_current_value do
	ensure_listening
	begin
		xml_root = REXML::Document.new(job_proxy.config_xml).root
		multibranch xml_root.name.include? 'multibranch'
		if multibranch
			repository_url xml_root.text('//source/remote').to_s
			script_path xml_root.text('//scriptPath').to_s
			credentials_id xml_root.text('//source/credentialsId').to_s
		else
			repository_url xml_root.text('//url').to_s
			script_path xml_root.text('//scriptPath').to_s
			credentials_id xml_root.text('//credentialsId').to_s
		end
	rescue Jenkins2::NotFoundError
		current_value_does_not_exist!
	end
end

action :create do
	if current_value && current_value.multibranch != new_resource.multibranch
		converge_by("delete/create #{new_resource.identity}") do
			do_delete
			do_create(:create)
		end
	else
		converge_if_changed do
			do_create(current_value ? :update : :create)
		end
	end
end

action :delete do
	if current_value
		converge_by("delete #{new_resource.identity}") do
			do_delete
		end
	end
end

def job_proxy
	@job_proxy ||= path.split('/').inject(jc){|acc, elem| acc.job(elem) }
end
