module WardenTaggedLogger
	def self.extract_user_id_from_request(req)
		begin
			session_key = Rails.application.config.session_options[:key]
			session_data = req.cookie_jar.encrypted[session_key]
			warden_data = session_data["warden.user.user.key"]
			warden_data[0][0]
		rescue StandardError => e
			logger.debug "Error finding the current user: #{e.message}"
			logger.debug "Backtrace: #{e.backtrace.inspect}"
			nil
		end
	end
end