class Jobs::ImportCleanedRocheAnalytes < Jobs::BaseJob

	attr_accessor :header
	attr_accessor :error_rows
	attr_accessor :connection

	def self.default_params
	  	params = { :schedule_name => 'import_cleaned_roche_analytes', 
	  				:base_path => "/mounts/data",
	  				:run_by_user => 'panda_user',
	  				:csv_path => "/mounts/data/analyses/panda_user/sarstedt_freeze",
	  				:csv_filename => "sarstedt_freeze_20210927.csv",
	  				:roche_table => "cg_csf_local_roche_sarstedt_freeze",
	  				:dry_run => false
	  			}

	  			
        params.default = ''
        params
    end

	def run(params)

		begin
			setup(params)

			import(params)

			rotate_tables(params)

			report_errors(params)

			close(params)
		
		rescue StandardError => error

			self.error_log << "Error (#{error.class}): #{error.message}"
			close_fail(params, error)

		end
	end

	def setup(params)
		@error_rows = []
		@connection = ActiveRecord::Base.connection
	end

	def import(params)

		csv = CSV.read("#{params[:csv_path]}/#{params[:csv_filename]}", :headers => true)

		sql = "truncate table #{params[:roche_table]}_new"
		@connection.execute(sql)
		
		csv.each do |row|

			roche_form = CsfAnalyteSarstedtFreezeForm.from_csv(row)
			sql = ''
			if !roche_form.valid?
				@error_rows << roche_form
			end

			begin

				sql = roche_form.to_sql_insert("#{params[:roche_table]}_new")
				puts "#{sql}"
				if !params[:dry_run]
					@connection.execute(sql)
				end

			rescue ArgumentError => e
				puts "there was an error: #{e.message}, with: #{row.to_s}"
			end
		end
		
	end

	def rotate_tables(params)
		sql = "truncate table #{params[:roche_table]}_old"
		@connection.execute(sql)
		sql = "insert into #{params[:roche_table]}_old select * from #{params[:roche_table]}"
		@connection.execute(sql)
		sql = "truncate table #{params[:roche_table]}"
		@connection.execute(sql)
		sql = "insert into #{params[:roche_table]} select * from #{params[:roche_table]}_new"
		@connection.execute(sql)
	end

	def report_errors(params)
		
	end
end