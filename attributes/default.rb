default[:jenkins].tap do |j|
	j[:repository] = 'http://pkg.jenkins-ci.org/debian-stable'
	j[:repository_key] = 'http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key'

	j[:home] = '/var/lib/jenkins'
	j[:user] = 'jenkins'

	j[:databag] = 'default'
	j[:log] = '/var/log/jenkins'
	j[:protocol] = 'http'
	j[:listen_address] = '0.0.0.0'
	j[:port] = '8080'
	j[:context_path] = '/'
	j[:timezone] = 'Europe/Tallinn'

	j[:java] = 'java'
	j[:default_java_args] = "-Djenkins.install.runSetupWizard=false -Djava.awt.headless=true "\
		"-Dhudson.matrix.MatrixConfiguration.useShortWorkspaceName=true "\
		"-Duser.timezone=#{j[:timezone]}"
	j[:default_jenkins_args] = '--webroot=/var/cache/$NAME/war --httpPort=$HTTP_PORT '\
		'--ajp13Port=$AJP_PORT'
	j[:maxopenfiles] = 81920
end
