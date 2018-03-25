// vim: set filetype=groovy:

pipeline {
  options{
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }
  triggers {
    githubPush()
  }
  agent {
    docker {
      label "docker"
      image "chef/chefdk:latest"
      args "-e HOME=/tmp"
    }
  }
  stages {
    stage("Style Check"){
      steps {
        githubNotify()
        sh "chef exec "
      }
    }
  }
  post {
    always {
      script {
        currentBuild.result = currentBuild.currentResult
      }
      githubNotify()
      slackNotifyDevops()
    }
  }
}
