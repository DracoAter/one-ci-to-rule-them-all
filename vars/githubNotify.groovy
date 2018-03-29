// vim: set filetype=groovy:

def call(){
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
