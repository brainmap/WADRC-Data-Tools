# Poll DICOM images to verify metadata in the Database.
namespace :dicom do
  desc "Refresh ImageDataset information from the filesystem."
  task(:refresh_datasets => :environment) do
    @updated = []
    @error = []
    ImageDataset.all.each do |dataset|
    # dataset = ImageDataset.find_by_id 17122
      begin
        # Ensure that a sample DICOM image is available and unzipped.
        Pathname.new(dataset.path.to_s).first_dicom do |dcm|
          # Initialize a fresh Metamri::RawImageDataset
          raw_file = RawImageFile.new(dcm)
          meta_dataset = RawImageDataset.new(dataset.path, [raw_file])
          # Initialize Thumbnail (or nil)
          # Note: Using Metamri#RawImageDatasetThumbnail Directly
          begin 
            thumb = nil #File.open(RawImageDatasetThumbnail.new(meta_dataset).thumbnail)
          rescue StandardError, ScriptError => e
            puts e
            thumb = nil
          end
          dataset.update_attributes(meta_dataset.attributes_for_active_record(:thumb => thumb))
          
          if dataset.save
            @updated << {:id => dataset.id, :path => dataset.path}
            print '.'
          else
            @error << {:id => dataset.id, :path => dataset.path, :errors => dataset.errors}
            print 'x'
          end
        end
        STDOUT.flush
      rescue StandardError => e
        @error << {:id => dataset.id, :path => dataset.path, :errors => e}
        print 'x'
        # raise e
      end
      
    end
    puts; pp @updated, @error
  end
  
  desc "Refresh Visit DICOM Study UIDs."
  task(:refresh_visit_uids => :environment) do
    @updated = []
    @error = []
    Visit.all.each do |visit|
    #visit = Visit.find_by_path '/Data/vtrak1/raw/carlson.sharp.visit1/shp00034_1396_12102010'
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
  
end
