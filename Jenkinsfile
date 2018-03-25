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
    stage("Rubocop"){
      steps {
        githubNotify()
        sh "chef exec rubocop"
      }
    }
    stage("Foodcritic"){
      steps {
        sh "chef exec foodcritic ."
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
