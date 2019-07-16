module WardenTaggedLogger
	def self.extract_user_id_from_request(req)
		begin
			session_key = Rails.application.config.session_options[:key]
			session_data = req.cookie_jar.encrypted[session_key]
			warden_data = session_data["warden.user.user.key"]
			warden_data[0][0]
		rescue StandardError => e
			puts e.message
			nil
		end
	end
end