class Jobs::Pet::PetHarvestBase < Jobs::BaseJob

  	def self.default_params
		params = { schedule_name: 'pet_harvest',
				base_path: '/mounts/data', 
    			computer: "merida",
    			comment: [],
    			comment_warning: "",
                run_by_user: 'panda_user',
                pib_path: "/pet/pib/dvr/code_ver2b",
                reprocessing: false,
                initial_processing: true
    		}
        params.default = ''
        params
    end


	def run(params)

		begin
			setup(params)

			harvest(params)

			post_harvest(params)

			close(params)
		
		rescue StandardError => error

			self.error_log << "Error (#{error.class}): #{error.message}"
			close_fail(params, error)

		end
	end

	def setup(params)
	end
	
	def harvest(params)
	end
	
	def post_harvest(params)
	end

end