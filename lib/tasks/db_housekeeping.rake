$:.push '/Users/kris/projects/ImageData/lib'

# require 'mysql'
# require 'sqlite3'
# require 'lib/tasks/mysql_to_rails_lib'

MYSQLSERVER = "jimbo"
MYSQLUSER = "SQLAdmin"
MYSQLPASSWD = "57gyri/"
MYSQLDB = "access"

RAILSDB = 'db/development.sqlite3'

namespace :db do
  
  namespace :visits do
    
    task(:reset_timestamps => :environment) do
      Visit.all.each do |v|
        v.created_at = DateTime.now
        v.updated_at = DateTime.now
        v.save
      end
    end
    
    namespace :status do
      task(:update_from_another_db => :environment) do
        old_db = SQLite3::Database.new('/Data/home/kris/TextMateProjects/TransferScans/db/development.sqlite3.bkup')
        old_db.results_as_hash = true
        old_db.type_translation = true
        
        Visit.all.each do |new_visit|
          old_visit = old_db.execute("SELECT * FROM visits WHERE rmr = '#{new_visit.rmr}'")
          unless old_visit.empty?
            old_visit = old_visit.first
            
            new_visit.rad_review = old_visit['rad_review']
            new_visit.transfer_mri = old_visit['transfer_mri']
            new_visit.transfer_pet = old_visit['transfer_pet']
            new_visit.transfer_behavioral_log = old_visit['transfer_behavioral_log']
            new_visit.check_imaging = old_visit['check_imaging']
            new_visit.check_np = old_visit['check_np']
            new_visit.check_MR5_DVD = old_visit['check_MR5_DVD']
            new_visit.burn_DICOM_DVD = old_visit['burn_DICOM_DVD']
            new_visit.first_score = old_visit['first_score']
            new_visit.second_score = old_visit['second_score']
            new_visit.enter_info_in_db = old_visit['enter_info_in_db']
            new_visit.conference = old_visit['conference']
            new_visit.compile_folder = old_visit['compile_folder']
            new_visit.dicom_dvd = old_visit['dicom_dvd']
            new_visit.scan_number = old_visit['scan_number']
            new_visit.notes = old_visit['notes']
            
            new_visit.save
          end
        end
      end
    end
    
    namespace :enumbers do
      
      task(:convert_to_alpha => :environment) do
        Visit.all.each do |v|
          puts "Converting #{v.enumber} to #{convert_enumber_to_alpha(v.enumber)}"
          v.enumber = convert_enumber_to_alpha(v.enumber)
          v.save
        end
      end
      
      task(:strip_trailing_underscores => :environment) do
        Visit.all.each do |v|
          unless v.enumber.nil?
            if v.enumber =~ /_.$/
              puts "Converting  #{v.enumber} to #{v.enumber.split("_").first}"
              v.enumber = v.enumber.split("_").first
              v.save
            end
          end
        end
      end
      
      task(:pull_from_path => :environment) do
        Visit.all.each do |v|
          if v.enumber.nil? or v.enumber.empty?
            unless v.path.nil? or v.path.empty?
              puts "Setting enumber for #{v.path} to #{File.basename(v.path).split("_").first}"
              v.enumber = File.basename(v.path).split("_").first
              v.save
            end
          end
        end
      end
      
    end
    
  end
  
end