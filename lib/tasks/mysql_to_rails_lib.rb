require "rubygems"
# require "mysql"
require 'sqlite3'

MYSQLSERVER = "jimbo"
MYSQLUSER = "SQLAdmin"
MYSQLPASSWD = "57gyri/"
MYSQLDB = "access"

# 
def fetch_participants_from_mysql
  begin
    db = Mysql.new(MYSQLSERVER,MYSQLUSER,MYSQLPASSWD,MYSQLDB)
    result = db.query(sql_find_all_participants_in_access_mysql_db)
    return result
  rescue Mysql::Error => e
    puts "Error code: #{e.errno}"
    puts "Error message: #{e.error}"
    puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
  ensure
    db.close if db
  end
end

def delete_all_participants_from_rails_db(dbfile)
  begin
    db = SQLite3::Database.new(dbfile)
    db.execute("DELETE FROM participants")
  ensure
    db.close if db
  end
end

def insert_participants_into_rails_db(participants, dbfile)
  begin
    db = SQLite3::Database.new(dbfile)
    participants.each_hash do |p|
      db.execute(sql_insert_participant(p))
    end
  ensure
    db.close if db
  end
end

def associate_visits_to_participants_via_rmr(visits)
  begin
    db = Mysql.new(MYSQLSERVER,MYSQLUSER,MYSQLPASSWD,MYSQLDB)
    visits.each do |v|
      result = db.query(sql_find_participants_matching_rmr(v.rmr))
      if result.num_rows == 0
        puts "Could not find match for RMR: #{v.rmr}... skipping."; next
      elsif result.num_rows > 1
        puts "More than one match for RMR: #{v.rmr}... skipping."; next
      end
      p_id, enum, protocol_name = result.fetch_row
      v.participant_id = p_id
      #v.enum = enum
      #v.protocol = Protocol.find_by_name(protocol_name)
      puts "Setting associations for visit with RMR: #{v.rmr}"
      puts "\t%-20s => %s" % ["Participant ID", p_id.to_s]
      puts "\t%-20s => %s" % ["ENUM", v.enum]
      puts "\t%-20s => %s" % ["Protocol name", protocol_name]
      v.save
    end
  rescue Mysql::Error => e
    puts "Error code: #{e.errno}"
    puts "Error message: #{e.error}"
    puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
  ensure
    db.close if db
  end
end

def convert_enum_to_alpha(enum)
  if enum =~ /^10|^11|^12/
    'tbi' + enum[1..-1]
  elsif enum =~ /^15/
    'tbiva0' + enum[2..-1]
  elsif enum =~ /^20|^21|^22/
    'alz' + enum[1..-1]
  elsif enum =~ /^25/
    'wrp0' + enum[2..-1]
  elsif enum =~ /^3/
    'cpr' + enum[1..-1]
  elsif enum =~ /^4/
    'pc' + enum[1..-1]
  elsif enum =~ /^5/
    'awr' + enum[1..-1]
  elsif enum =~ /^9/
    'pil' + enum[1..-1]
  else
    enum
  end
end



private



def sql_find_participants_matching_rmr(rmr)
  "SELECT tblprotocol.fkDBID, tblprotocol.ENUM, ProtocolName
  FROM tblscan_new 
  JOIN tblvisittable ON fkVisitID = pkVisitID 
  JOIN tblprotocol ON fkProtocolID = pkProtocolID 
  LEFT JOIN lookup_studyprotocol ON fkProtocolTypeID = pkProtocolTypeID
  WHERE tblscan_new.RMR = '#{rmr}'"
end

def sql_find_all_participants_in_access_mysql_db
  "SELECT
  s.pkDBID AS id,
  s.wrapenroll AS wrapenroll,
  s.wrapnum AS wrapnum,
  s.quality_redflag AS quality_redflag,
  d.DOB AS dob,
  d.GENDER AS gender,
  d.AGE AS age,
  d.Edyrs AS ed_years,
  a.APOEe1 as apoe_e1,
  a.APOEe2 as apoe_e2,
  a.APOEComment as note,
  a.processor as apoe_processor
  FROM tblsubject s 
  LEFT OUTER JOIN tbldemographics d 
    ON s.pkDBID = d.fkDBID
  LEFT OUTER JOIN tblapoe a 
    ON a.fkDBID = d.fkDBID"
end

def sql_find_all_enrollments_in_access
  "SELECT
  e.enrolldate AS enroll_date,
  e.ENUM AS enum,
  e.Recruitsource AS recruitment_source,
  e.
  p.wrapnum AS wrapnum,
  
  "
end

def sql_insert_participant(p)
  p.each_pair do |k,v| 
    if p[k].nil?
      p[k] = "NULL"
    elsif not_integer?(p[k])
      p[k] = "'#{escaped(p[k])}'"
    end
  end
  keys = "(#{p.keys.join(', ')})"
  vals = "(#{p.values.join(', ')})"
  "INSERT INTO participants #{keys} VALUES #{vals}"
end

def not_integer?(str)
  begin
    return false if Integer(str)
  rescue
    return true
  end
end

def escaped(str)
  str.gsub(/'/, "''")
end
