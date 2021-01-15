class Jobs::T2Metadata::T2MetadataHarvest < Jobs::BaseJob

	require 'open3'
	
	attr_accessor :header
	attr_accessor :error_rows
	attr_accessor :connection
	attr_accessor :total_scans_considered
	attr_accessor :selected
	attr_accessor :driver

	def self.default_params
	  	params = { :schedule_name => 'T2 Metadata Harvest', 
	  				:base_path => "/mounts/data/raw",
	  				:run_by_user => 'panda_user',
	  				:target_table => 'cg_image_dataset_metadata',
	  				:staging_dir => "/mounts/data/analyses/wbbevis/t2_metadata_staging",
	  				:python_bin_dir => "/mounts/data/analyses/wbbevis/t2_metadata",
	  				:write_sql_to_file => true,
	  				:sql_outfile => "/mounts/data/analyses/wbbevis/t2_metadata/sql_outfile.sql",
	  				:auto_insert => false
	  			}
        params.default = ''
        params
    end

	def run(params)

		begin
			setup(params)

			rotate_old(params)

			selection(params)

			filter(params)

			harvest(params)

			rotate_new(params)

			close(params)
		
		rescue StandardError => error

			self.error_log << "Error (#{error.class}): #{error.message}"
			close_fail(params, error)

		end
	end

	def setup(params)
		@error_rows = []
		@connection = ActiveRecord::Base.connection
		@driver = []

		# set up the staging dir
		if !File.exists? params[:staging_dir]
			Dir.mkdir params[:staging_dir]
		end
	end

	def rotate_old(params)
		sql = "truncate table #{params[:target_table]}_old"
		@connection.execute(sql)
		sql = "insert into #{params[:target_table]}_old select * from #{params[:target_table]}"
		@connection.execute(sql)
	end

	def selection(params)
		@selected = ImageDataset.where("(series_description not like 'ORIG%') and ((series_description like 'SAG Cube T2 FLAIR%') or (series_description like 'Sag T2 FLAIR Cube%')  or (series_description like 'Sag CUBE T2FLAIR%') or (series_description like 'Sag CUBE flair%'))")
	end

	def filter(params)
		# here we're going to populate @driver with images, and we want to be sure that all of the paths exist,
		# that there are dicoms somewhere below the directory in path, etc. 

		@selected.each do |image|

			# how's the path?
			if !File.exists? image.path or !File.directory? image.path
				self.exclusions << {:class => image.class, :id => image.id, :message => "image has a bad path"}
				next
			end

			# are there dicoms in there?
			if Dir.glob("#{image.path}/*.bz2").count < 1 and Dir.glob("#{image.path}/*/*.bz2").count < 1
				self.exclusions << {:class => image.class, :id => image.id, :message => "no dicoms found in this path"}
				next
			end

			@driver << image
		end
	end

	def harvest(params)

		sql_outfile = nil
		if params[:write_sql_to_file]
			sql_outfile	= File.open(params[:sql_outfile], 'wb')
		end

		@driver.each do |image|
			# here, we're going to try to copy the first dicom from the image's raw dir, unzip, and call
			# the python script that will look into it and return us a JSON.


			dicoms = Dir.glob("#{image.path}/*.bz2")
			if dicoms.count == 0
				dicoms = Dir.glob("#{image.path}/*/*.bz2")
			end

			first_dicom =  dicoms.first
			r_call "cp #{first_dicom} #{params[:staging_dir]}/"
			filename = first_dicom.split("/").last
			r_call "bzip2 -d #{params[:staging_dir]}/#{filename}"

			filename = filename.gsub('.bz2', '')

			json_response = r_call "source #{params[:python_bin_dir]}/bin/activate && python #{params[:python_bin_dir]}/scrape_meta.py #{params[:staging_dir]}/#{filename}"

			# the JSON response will be either an error, or a complete report on the fields, or some other 
			# error that doesn't parse as JSON.

			parsed_json = JSON.parse(json_response)

			if parsed_json["error"]
				#record the error
			else
				# prepare this response for insert into the metadata table

				columns = []
				values = []
				["t2_prep", "pure_correction", "channel_count", "coil_name", "scanner"].each do |key|
					columns << key
					values << (parsed_json[key].nil? ? "NULL" : @connection.quote(parsed_json[key]))
				end

				sql = "INSERT INTO #{params[:target_table]}_new (image_dataset_id, path, #{columns.join(', ')}) values (#{image.id}, #{image.path}, #{values.join(', ')});"

				if params[:write_sql_to_file]
					sql_outfile.write("#{sql}\n")
				end

				if params[:auto_insert]
					@connection.execute(sql)
				end

			end

			#finally, we've got to clean up the staging dir.
			File.delete "#{params[:staging_dir]}/#{filename}"
			File.delete "#{params[:staging_dir]}/#{filename}.bz2"
		end

		if params[:write_sql_to_file]
			sql_outfile.close
		end

	end

	def rotate_new(params)
		sql = "truncate table #{params[:target_table]}"
		@connection.execute(sql)
		sql = "insert into #{params[:target_table]} select * from #{params[:target_table]}_new"
		@connection.execute(sql)
	end

	def report_errors(params)

	end
end

# CREATE TABLE `cg_image_dataset_metadata` (
# `id` int NOT NULL AUTO_INCREMENT,
# `image_dataset_id` int(11) DEFAULT NULL,
# `path` varchar(255) DEFAULT NULL,
# `t2_prep` varchar(24) DEFAULT NULL,
# `pure_correction` varchar(255) DEFAULT NULL,
# `channel_count` int DEFAULT NULL,
# `coil_name` varchar(50) DEFAULT NULL,
# `scanner` varchar(50) DEFAULT NULL,
#  PRIMARY KEY (`id`)
#  )