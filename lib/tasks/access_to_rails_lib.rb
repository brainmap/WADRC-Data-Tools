require "rubygems"
require 'sqlite3'
begin
  require "mysql"
rescue LoadError => e
  puts e
end

MYSQLSERVER = "jimbo"
MYSQLUSER = "SQLAdmin"
MYSQLPASSWD = "57gyri/"
MYSQLDB = "access"

# returns an array of hashes that can be used to create new rails Participants
def fetch_participants_from_mysql
  query_mysql(sql_find_all_participants_in_access_mysql_db)
end

def fetch_participant_enrollments(participant)
  query_mysql(sql_find_enrollments_for_participant(participant.access_id))
end

def fetch_visit_enrollment(visit)
  query_mysql(sql_find_enrollments_by_rmr(visit.rmr))
end

def convert_enumber_to_alpha(enumber)
  if enumber =~ /^1(?!5)/
    'tbi' + enumber[1..-1]
  elsif enumber =~ /^15/
    'tbiva0' + enumber[2..-1]
  elsif enumber =~ /^2(?!5)/
    'alz' + enumber[1..-1]
  elsif enumber =~ /^25/
    'wrp0' + enumber[2..-1]
  elsif enumber =~ /^3/
    'cpr' + enumber[1..-1]
  elsif enumber =~ /^4/
    'pc' + enumber[1..-1]
  elsif enumber =~ /^5/
    'awr' + enumber[1..-1]
  elsif enumber =~ /^9/
    'pil' + enumber[1..-1]
  else
    enumber
  end
end



private

# submits an SQL statement to the mysql server, returns the results as an ARRAY of hashes NOT the silly data structure 
# that the mysql module gives to you by default.
def query_mysql(sql)
  begin
    db = Mysql.connect(MYSQLSERVER,MYSQLUSER,MYSQLPASSWD,MYSQLDB)
    result = db.query(sql)
    results_array = Array.new
    result.each_hash { |h| results_array << h }
    return results_array
  rescue Mysql::Error => e
    puts "Error code: #{e.errno}"
    puts "Error message: #{e.error}"
    puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
    return nil
  ensure
    db.close if db
  end
end

def sql_find_participants_matching_rmr(rmr)
  "SELECT tblprotocol.fkDBID, tblprotocol.enumber, ProtocolName
  FROM tblscan_new 
  JOIN tblvisittable ON fkVisitID = pkVisitID 
  JOIN tblprotocol ON fkProtocolID = pkProtocolID 
  LEFT JOIN lookup_studyprotocol ON fkProtocolTypeID = pkProtocolTypeID
  WHERE tblscan_new.RMR = '#{rmr}'"
end

# Ensure columns are listed AS their rails attribute names so that the reuults
# hash returned by the MySQL query can be used for Rails Model updates.
def sql_find_enrollments_by_rmr(rmr)
  "SELECT
  e.enrolldate AS enroll_date,
  e.enum AS enumber,
  e.Recruitsource AS recruitment_source,
  e.WithdrawalReason AS withdrawl_reason
  FROM tblscan_new s
  JOIN tblvisittable v ON fkVisitID = pkVisitID 
  JOIN tblprotocol e ON fkProtocolID = pkProtocolID 
  WHERE s.RMR = '#{rmr}'"
end

def sql_find_all_participants_in_access_mysql_db
  "SELECT
  s.pkDBID AS access_id,
  s.wrapnum AS wrapnum,
  d.DOB AS dob,
  d.GENDER AS gender,
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

def sql_find_enrollments_for_participant(dbid)
  "SELECT
  e.enrolldate AS enroll_date,
  e.enum AS enumber,
  e.Recruitsource AS recruitment_source,
  e.WithdrawalReason AS withdrawl_reason
  FROM tblprotocol e
  WHERE e.fkDBID = #{dbid}"
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
