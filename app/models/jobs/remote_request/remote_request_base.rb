	class Jobs::RemoteRequest::RemoteRequestBase < Jobs::BaseJob

	def self.default_params
	  	params = { :schedule_name => '', :run_by_user => 'panda_user'}
        params.default = ''
        params
    end

	def run(params)

		begin
			login(params)

			selection(params)

			record(params)

			rotate_tables(params)

			close(params)
		
		rescue StandardError => error

			self.error_log << "Error (#{error.class}): #{error.message}"
			close_fail(params, error)

		end
	end
end