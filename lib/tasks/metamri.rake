require 'etc'

# Poll DICOM images to verify metadata in the Database.
namespace :dicom do
  
  desc "Import a visit. with DIR=dir"
  task(:import_visit => :environment) do
    dir = ENV['DIR']
    raise ArgumentError, "Visit Directory: #{dir} doesn't appear to be a directory. Use `DIR=/Data/vtrak1/raw/data/subj01 rake dicom:import_visit`" unless File.directory? dir
    metamri_visit = VisitRawDataDirectory.new(dir)
    metamri_visit.scan
    
    user = User.find_by_login(Etc.getlogin)
    
    Visit.create_or_update_from_metamri(metamri_visit, user)
  end
  
  desc "Import a study directory. with DIR=dir"
  task(:import_study => :environment) do
    study = ENV['DIR']
    raise ArgumentError, "Study Directory: #{study} doesn't appear to be a directory. Use `DIR=/Data/vtrak1/raw/data/ rake dicom:import_visit`" unless File.directory? study
    user = User.find_by_login(Etc.getlogin)

    Pathname.new(study).entries.each do |dir|
      next if dir.to_s =~ /^\./
      next if File.symlink? dir
      visit_dir = File.join(study, dir)
      
      begin
        metamri_visit = VisitRawDataDirectory.new(visit_dir)
        metamri_visit.scan
        Visit.create_or_update_from_metamri(metamri_visit, user)
      rescue StandardError => e
        puts "There was a problem scanning a dataset in #{visit_dir}... skipping."
        puts "Exception message: #{e.message}"
        Rails.logger.error "There was a problem scanning a dataset in #{visit_dir}... skipping."
        Rails.logger.error "Exception message: #{e.message}"
        Rails.logger.error e.backtrace
        raise e
      ensure
        v = nil
      end
    end
  end
  
  desc "Refresh ImageDataset information from the filesystem."
  task(:refresh_datasets => :environment) do
    @updated = []
    @error = []
    recreate_thumbnails = true
    ImageDataset.all.each do |dataset|
      begin
        # Ensure that a sample DICOM image is available and unzipped.
        Pathname.new(dataset.path.to_s).first_dicom do |dcm|
          # Initialize a fresh Metamri::RawImageDataset
          raw_file = RawImageFile.new(dcm)
          meta_dataset = RawImageDataset.new(dataset.path, [raw_file])
          # Initialize Thumbnail (or nil)
          # Note: Using Metamri#RawImageDatasetThumbnail Directly
          begin
            begin
              if recreate_thumbnails
                thumb = File.open(RawImageDatasetThumbnail.new(meta_dataset).thumbnail)
                attr_options = {:thumb => thumb}
              end
            rescue StandardError, ScriptError => e
              Rails.logger.debug e
            end
            # Default options to a blank hash if not set above.
            attr_options ||= {}
            
            if dataset.update_attributes(meta_dataset.attributes_for_active_record(attr_options))
              @updated << {:id => dataset.id, :path => dataset.path}
              print '.'
            else
              conflict = ImageDataset.find_by_dicom_series_uid(meta_dataset.dicom_series_uid)
              @error << {:id => dataset.id, :path => dataset.path, :errors => dataset.errors, :conflicts_with => conflict}
              print 'x'
            end
          ensure
            # Be sure to close the thumbnail even if an error occured.
            thumb.close if thumb.respond_to? :close
          end
        end
        STDOUT.flush
      rescue StandardError => e
        @error << {:id => dataset.id, :path => dataset.path, :errors => e}
        print '*'; STDOUT.flush
        # raise e
      end
    end
    
    puts; pp @updated, @error
    puts "Updated %i datasets and had errors on %i datasets." % [@updated.size, @error.size]
  end
  
  desc "Refresh Visit DICOM Study UIDs."
  task(:refresh_visit_uids => :environment) do
    @updated = []
    @error = []
    Visit.all.each do |visit|
      visit.dicom_study_uid = visit.find_first_dicom_study_uid
      if visit.save
        @updated << {:id => visit.id, :path => visit.path }
        print '.'
      else
        @error << {:id => visit.id, :path => visit.path, :errors => visit.errors }
        print 'x'
      end
      STDOUT.flush
    end
    puts; pp @updated, @error
  end
  
  desc "Cleanup datasets that are not on the filesystem."
  task(:cleanup_datasets => :environment) do
    @expired_datasets = []
    ImageDataset.all.each do |dataset|
      unless dataset.valid_path?
        @expired_datasets << dataset
        print '*'
      else
        print '.'
      end
      STDOUT.flush
    end
    @expired_datasets.collect {|ds| ds.delete}
    puts; puts "Found %i expired datasets." % @expired_datasets.size
    # @expired_datasets.map {|ds| ds.delete}
  end
  
end
