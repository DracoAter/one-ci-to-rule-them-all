require 'jenkins2'

module JenkinsHelper
  def ensure_listening
    max_wait_minutes = 4
    [3, 5, 7, 15, 30, [60] * (max_wait_minutes - 1)].flatten.each do |sec|
      begin
        result = jc.version
        return result if result
        Jenkins2::Log.warn { "Received result is not truthy: #{result}." }
        Jenkins2::Log.warn { "Retry request in #{sec} seconds." }
        sleep sec
      rescue Jenkins2::NotFoundError, Jenkins2::ServiceUnavailableError, Errno::ECONNREFUSED,
             Net::HTTPFatalError, Net::ReadTimeout => e
        Jenkins2::Log.warn { "Received error: #{e}." }
        Jenkins2::Log.warn { "Retry request in #{sec} seconds." }
        sleep sec
      end
    end
    Jenkins2::Log.error { "Tired of waiting (#{max_wait_minutes} minutes). Give up." }
    nil
  end

	def jc
		@jc ||= Jenkins2.connect(connection)
	end
end
