// vim: set filetype=groovy:

pipeline {
	options{
		timestamps()
		buildDiscarder(logRotator(numToKeepStr: '10'))
	}
	triggers {
		githubPush()
		pollSCM('H */4 * * 1-5')
	}
	environment {
		SECRET = credentials('github_api')
		CI = true
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

def githubNotify(){
  def url = ''
  if (env.GIT_URL.startsWith('http')){
    url = "${env.GIT_URL}"
  }
  else {
    tokens = env.GIT_URL.replaceAll('.git$', '').tokenize('@:')
    url = "https://${tokens[1]}/${tokens[2]}"
  }
  step([$class: 'GitHubCommitStatusSetter',
    commitShaSource: [$class: 'ManuallyEnteredShaSource', sha: "${env.GIT_COMMIT}"],
    reposSource: [$class: 'ManuallyEnteredRepositorySource', url: "${url}"]])
}
