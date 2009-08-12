$:.push '/Users/kris/projects/ImageData/lib'

# require 'mysql'
require 'lib/tasks/mysql_to_rails_lib'
require 'visit_raw_data_directory'

MYSQLSERVER = "jimbo"
MYSQLUSER = "SQLAdmin"
MYSQLPASSWD = "57gyri/"
MYSQLDB = "access"

RAILSDB = 'db/development.sqlite3'

namespace :db do
  
  namespace :visits do
    task(:associate_participant => :environment) do
      associate_visits_to_participants_via_rmr(Visit.all)
    end
    
    task :scan_raw_data, :directory, :scan_procedure_name do |t, args|
      args.with_defaults(:directory => nil, :scan_procedure_name => nil, :dbfile => RAILSDB)
      puts "Scanning raw data from: #{args.directory} as part of scan_procedure #{args.scan_procedure_name}"
      v = VisitRawDataDirectory.new(args.directory, args.scan_procedure_name)
      v.scan
      visit = Visit.find_or_initialize_by_rmr(v.rmr_number)
      if visit.new_record? or visit.image_datasets.blank?
        v.datasets.each do |d|
          visit.image_datasets.build(d.attributes_for_active_record)
        end
      end
      visit.save
    end
    
  end
  
  namespace :participants do
    task(:repopulate => :environment) do
      p = fetch_participants_from_mysql
      delete_all_participants_from_rails_db(RAILSDB)
      insert_participants_into_rails_db(p,RAILSDB)
    end
  end
  
  namespace :scan_procedures do
    task(:append_from_mysql => :environment) do
      mysqldb = Mysql.new(MYSQLSERVER,MYSQLUSER,MYSQLPASSWD,MYSQLDB)
      result = mysqldb.query("SELECT ProtocolName FROM lookup_studyprotocol")
      result.each do |row|
        ScanProcedure.create(:name => row[0])
      end
    end
  end
  
  
end
