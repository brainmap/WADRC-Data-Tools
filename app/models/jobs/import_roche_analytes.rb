class Jobs::ImportRocheAnalytes < Jobs::BaseJob

	attr_accessor :header
	attr_accessor :error_rows
	attr_accessor :connection

	def self.default_params
	  	params = { :schedule_name => 'import_roche_analytes', 
	  				:base_path => "/mounts/data",
	  				:run_by_user => 'panda_user',
	  				:g_drive_path => "/Volumes/domdata/Team/ADRC/Cores/Core G - Biomarker Core/CSF_biomarker-core/Biospecimen Lab/Cobas 6000 e601/Results",
	  				:xlsx_filename => "Local Roche Master Run.xlsx",
	  				:csv_path => "/mounts/data/analyses/panda_user/lp_roche_data",
	  				:csv_filename => "Local Roche Master Run.csv",
	  				:roche_table => "cg_csf_local_roche_analytes",
	  				:dry_run => false
	  			}
        params.default = ''
        params
    end

	def run(params)

		begin
			setup(params)

			mount_domdata(params)

			convert_to_csv(params)

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
		@header = ["Specimen Id (tube label)", "WRAP ID", "Reggie ID", "Run Date and Time", "Pre_Dil", "AB 42 Value", "V_Unit", "D_Alm", "tTau Value", "V_Unit", "D_Alm", "pTau Value", "V_Unit", "D_Alm", "Machine", "Tube Type", "Sample Type", "Frozen or Fresh", "Preanalytic Protocol", "Sample Visit Date", "Notes"]
		@error_rows = []
		@connection = ActiveRecord::Base.connection
	end

	def mount_domdata(params)
	end

	def convert_to_csv(params)
		xlsx_workbook = RubyXL::Parser.parse("#{params[:g_drive_path]}/#{params[:xlsx_filename]}")

		#check that the headers match expected
		#the magic number '21' here is the number of columns in the header we're expecting
		if xlsx_workbook[0][0][0..21].map{|cell| cell.nil? ? '' : cell.value} != @header
			#error the job out.
			#headers didn't match expected

		end
		#otherwise, we're good to proceed

		#convert from xlsx to csv
		CSV.open("#{params[:csv_path]}/#{params[:csv_filename]}", "wb") do |csv|
			idx = 0

			until xlsx_workbook[0][idx].nil? do

				csv << xlsx_workbook[0][idx][0..21].map{|cell| cell.nil? ? '' : cell.value}
				idx += 1

			end
		end
	end

	def import(params)

		csv = CSV.read("#{params[:csv_path]}/#{params[:csv_filename]}", :headers => true)

		sql = "truncate table #{params[:roche_table]}_new"
		@connection.execute(sql)

		csv.each do |row|

			roche_form = CsfAnalyteForm.from_csv(row)
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