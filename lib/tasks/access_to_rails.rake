$:.push '/Users/kris/projects/ImageData/lib'

require 'rubygems'
require 'mysql'
require 'lib/tasks/access_to_rails_lib'
require 'metamri'

MYSQLSERVER = "jimbo"
MYSQLUSER = "SQLAdmin"
MYSQLPASSWD = "57gyri/"
MYSQLDB = "access"

namespace :db do
  
  namespace :access do
    task(:associate_enrollments_to_visits => :environment) do
      Visit.all.each do |v|
        enrollments = fetch_visit_enrollment(v)
        unless enrollments.blank?
          e = Enrollment.find_by_enum(enrollments.first['enum'])
          v.enrollment = e
        end
        v.save
      end
    end
    
    task :scan_raw_visit_data, :directory, :scan_procedure_name, :needs => :environment do |t, args|
      args.with_defaults(:directory => nil, :scan_procedure_name => nil)
      puts "+++ Importing #{args.directory} as part of #{args.scan_procedure_name} +++"
      v = VisitRawDataDirectory.new(args.directory, args.scan_procedure_name)
      begin
        v.scan
      rescue Exception => e
        v = nil; puts "Awfully sorry, this raw data directory could not be scanned."
      end
      unless v.nil?
        if Visit.create_or_update_from_metamri(v)
          puts "Sucessfully imported raw data directory."
        else
          puts "Awfully sorry, this raw data directory could not be saved to the database."
        end
      end
    end
    
    task(:repopulate_participants => :environment) do
      Participant.delete_all
      fetch_participants_from_mysql.each do |participant_hash|
        Participant.new(participant_hash).save
      end
    end
    
    task(:repopulate_enrollments => :environment) do
      Enrollment.delete_all
      Participant.all.each do |p|
        fetch_participant_enrollments(p).each do |e|
          p.enrollments.build(e)
        end
        p.save
      end
    end
    
    task :reset => [:repopulate_participants, :repopulate_enrollments, :associate_enrollments_to_visits]
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
