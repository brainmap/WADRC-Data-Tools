$:.push '/Users/kris/projects/ImageData/lib'

require 'mysql'
require 'raw_image_file'
require 'raw_image_dataset'
require 'visit_raw_data_directory'
require 'lib/tasks/mysql_to_rails_lib'

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
    
    task :scan_raw_data, :directory do |t, args|
      args.with_defaults(:directory => nil, :protocol_name => nil, :dbfile => RAILSDB)
      puts "Scanning raw data from: #{args.directory} as part of protocol #{args.protocol_name}"
      v = VisitRawDataDirectory.new(args.directory, args.protocol_name)
      v.scan
      v.init_db(args.dbfile)
      v.db_insert!
    end
    
  end
  
  namespace :participants do
    task(:repopulate => :environment) do
      p = fetch_participants_from_mysql
      delete_all_participants_from_rails_db(RAILSDB)
      insert_participants_into_rails_db(p,RAILSDB)
    end
  end
  
  namespace :protocols do
    task(:append_from_mysql => :environment) do
      mysqldb = Mysql.new(MYSQLSERVER,MYSQLUSER,MYSQLPASSWD,MYSQLDB)
      result = mysqldb.query("SELECT ProtocolName FROM lookup_studyprotocol")
      result.each do |row|
        Protocol.create(:name => row[0])
      end
    end
  end
  
  
end
