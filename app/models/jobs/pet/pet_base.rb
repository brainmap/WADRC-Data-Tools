class Jobs::Pet::PetBase < Jobs::BaseJob

  	def self.default_params
		params = { schedule_name: 'parallel_pet_process',
				base_path: Shared.get_base_path(), 
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
    def self.mk6240_params
      # - set up params
      params = { schedule_name: 'parallel_pet_mk6240_process',
                 base_path: Shared.get_base_path(), 
                 computer: "kanga",
                 comment: [],
                 dry_run: false,
                 tracer_id: "11",
                run_by_user: 'panda_user',
                 comment_warning: "",
                 method: "suvr",
                 exclude_sp_pet_array: [-1,100]
                }
      params
    end
    def self.pib_dvr_params
      # - set up params
      params = { schedule_name: 'parallel_pet_pib_dvr_process',
                 base_path: Shared.get_base_path(), 
                 computer: "kanga",
                 comment: [],
                 dry_run: false,
                 tracer_id: "1",
                run_by_user: 'panda_user',
                 comment_warning: "",
                 method: "dvr",
                 exclude_sp_pet_array: [-1,80,115,100] # excluding adcp
                }

      params
    end
    def self.av45_params
      # - set up params
      params = { schedule_name: 'parallel_pet_av45_process',
                 base_path: Shared.get_base_path(), 
                 computer: "kanga",
                 comment: [],
                 dry_run: true,
                run_by_user: 'panda_user',
                 tracer_id: "6",
                 comment_warning: "",
                 method: "suvr",
                 exclude_sp_pet_array: [-1,100]
                }
      params
    end

	def run(params)

		begin
			setup(params)

			selection(params)

			filter(params)

			matlab_call(params)

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

	def selection(params)
	end
	
	def filter(params)
	end
	
	def matlab_call(params)
	end
	
	def harvest(params)
	end
	
	def post_harvest(params)
	end

end