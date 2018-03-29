// vim: set filetype=groovy:

library identifier: 'one-ci-to-rule-them-all@pipeline_libs',
  retriever: modernSCM([$class: 'GitSCMSource',
    remote: 'https://github.com/DracoAter/one-ci-to-rule-them-all.git',
    traits: [[$class: 'org.jenkinsci.plugins.github_branch_source.BranchDiscoveryTrait'],
			$class: 'TagDiscoveryTrait']]])

pipeline {
	options{
		timestamps()
		buildDiscarder(logRotator(numToKeepStr: '10'))
	}
	triggers {
		githubPush()
	}
	agent any
	stages {
		stage("Rubocop"){
			steps {
				githubNotify()
				sh "/opt/chef/embedded/bin/rubocop"
			}
		}
	}
	post {
		always {
			script {
				currentBuild.result = currentBuild.currentResult
			}
			githubNotify()
		}
	}
}

