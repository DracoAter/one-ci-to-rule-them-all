// vim: set filetype=groovy:

library identifier: 'one-ci-to-rule-them-all@master',
  retriever: modernSCM([$class: 'GitSCMSource',
    remote: 'https://github.com/DracoAter/one-ci-to-rule-them-all.git',
    traits: [[$class: 'BranchDiscoveryTrait'], [$class: 'TagDiscoveryTrait']]])

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

