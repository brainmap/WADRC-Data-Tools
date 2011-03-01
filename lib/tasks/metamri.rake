# Poll DICOM images to verify metadata in the Database.
namespace :dicom do
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
