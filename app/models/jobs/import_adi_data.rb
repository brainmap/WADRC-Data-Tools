class Jobs::ImportAdiData < Jobs::BaseJob

	attr_accessor :header
	attr_accessor :error_rows
	attr_accessor :connection

	def self.default_params
	  	params = { :schedule_name => 'import_area_disadvantage_index', 
	  				:base_path => "/mounts/data",
	  				:run_by_user => 'panda_user',
	  				:csv_path => "/mounts/data/analyses/panda_user/adi_data",
	  				:adrc_csv_filename => "adrc_final_20211207.csv",
	  				:wrap_csv_filename => "wrap_final_20211207.csv",
	  				:cg_table_name => "cg_area_disadvantage_index",
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

		sql = "truncate table #{params[:cg_table_name]}_new"
		@connection.execute(sql)

		#adrc
		adrc_csv = CSV.read("#{params[:csv_path]}/#{params[:adrc_csv_filename]}", :headers => true)

		if adrc_csv.count > 0

			adrc_csv.each do |row|

				adi_form = AdrcAdiForm.from_csv(row)
				sql = ''
				if adi_form.nil? or !adi_form.valid?
					@error_rows << adi_form
					next
				end

				begin

					sql = adi_form.to_sql_insert("#{params[:cg_table_name]}_new")
					puts "#{sql}"
					if !params[:dry_run]
						@connection.execute(sql)
					end

				rescue ArgumentError => e
					puts "there was an error: #{e.message}, with: #{row.to_s}"
				end
			end
		end

		#wrap
		wrap_csv = CSV.read("#{params[:csv_path]}/#{params[:wrap_csv_filename]}", :headers => true)

		if wrap_csv.count > 0

			wrap_csv.each do |row|

				adi_form = WrapAdiForm.from_csv(row)
				sql = ''
				if adi_form.nil? or !adi_form.valid?
					@error_rows << adi_form
					next
				end

				begin

					sql = adi_form.to_sql_insert("#{params[:cg_table_name]}_new")
					puts "#{sql}"
					if !params[:dry_run]
						@connection.execute(sql)
					end

				rescue ArgumentError => e
					puts "there was an error: #{e.message}, with: #{row.to_s}"
				end
			end
		end
	end

	def rotate_tables(params)
		sql = "truncate table #{params[:cg_table_name]}_old"
		@connection.execute(sql)
		sql = "insert into #{params[:cg_table_name]}_old select * from #{params[:cg_table_name]}"
		@connection.execute(sql)
		sql = "truncate table #{params[:cg_table_name]}"
		@connection.execute(sql)
		sql = "insert into #{params[:cg_table_name]} select * from #{params[:cg_table_name]}_new"
		@connection.execute(sql)
	end

	def report_errors(params)

	end
end