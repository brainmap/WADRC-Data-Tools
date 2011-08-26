#$:.push '/Users/kris/projects/ImageData/lib'

require 'rubygems'
begin
  require 'metamri'
  require 'mysql'
rescue LoadError => e
  puts e
end
require 'lib/tasks/access_to_rails_lib'


MYSQLSERVER = "jimbo"
MYSQLUSER = "SQLAdmin"
MYSQLPASSWD = "57gyri/"
MYSQLDB = "access"

namespace :db do
  
  namespace :access do
    desc "Infer Enrollments"
    task(:infer_enrollments => :environment) do
      Visit.without_enrollments.each do |v|
        v.assign_enrollments
      end
    end
    
    desc "Assign an enrollment to a visit using enumber info from the Access DB."
    task(:associate_enrollments_to_visits => :environment) do
      Visit.all.each do |v|
        enrollments = fetch_visit_enrollment(v)
        unless enrollments.blank?
          e = Enrollment.find_by_enumber(enrollments.first['enumber'])
          v.enrollment = e
        end
        v.save
      end
    end
    
    task(:scan_raw_visit_data, :directory, :scan_procedure_name, :needs => :environment) do |t, args|
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
    
=begin rdoc
This task runs through each participant in the rails database, fetches related 
enrollments in the access database joined by the Access ID, and updates or 
creates the related enrollment models in the rails DB."
=end
    desc "Create or update enrollments and thier relationships with participants from the access DB."
    task(:repopulate_enrollments => :environment) do
      #Enrollment.delete_all
      Participant.all.each do |p|
        fetch_participant_enrollments(p).each do |e|
					en = Enrollment.find_or_create_by_enumber(e['enumber'])
					en.participant = p
          en.update_attributes(e)
        end
        p.save
      end
    end
    
=begin rdoc
=end
    desc "Normalize Enumbers"
    task(:normalize_enumbers => :environment) do
      # substitutions = [
      #         [/^15/, 'tbiva0'],
      #         [/^1(?!\5)/, 'tbi'], 
      #         [/^25/, 'wrp0'],
      #         [/^2(?!\5)/, 'alz'],
      #         [/^4/, 'pc'],
      #         [/^5/, 'awr']
      #       ]
      
      errors = []; outcomes = []
      Enrollment.all.each do |e|
        e.enumber = convert_enumber_to_alpha(e.enumber)
        
        unless e.changed?
          outcomes << [e.id, "Skipped #{e.enumber}"]
          next
        end
        
        if existing_enrollment = Enrollment.find_by_enumber(e.enumber)
          outcomes << [e.id, "Updated #{existing_enrollment.id} with #{e.id}"]
          if existing_enrollment.update_attributes(e.attributes)
            outcomes << [e.id, "Saved #{existing_enrollment.enumber}"]
          else
            errors << [existing_enrollment.id, existing_enrollment.errors]
          end
          e.destroy
        else
          if e.save
            outcomes << [e.id, "Saved #{e.id} in place: #{e.enumber}"]
          else
            errors << [e.id, e.errors]
          end
        end
      end

      outcomes.each{|outcome| puts "#{outcome.first}: #{outcome.last}"}
      errors.each{|error| puts "#{error.first}: #{error.last.full_messages.inspect}" }
    end
    
    desc "Reset Participants and Enrollments from the Access Database."
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
