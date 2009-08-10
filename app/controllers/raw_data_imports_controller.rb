require 'visit_raw_data_directory'

class RawDataImportsController < ApplicationController
  
  def new
    @recent_visits = Visit.find(:all, :conditions => ['created_at > ?', 1.month.ago])
    
    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  def create
    v = VisitRawDataDirectory.new(params[:raw_data_import][:directory], params[:raw_data_import][:scan_procedure])
    puts "+++ Importing #{v.visit_directory} as part of #{v.scan_procedure_name} +++"
    begin
      v.scan
      puts v
      v.db_insert!("#{RAILS_ROOT}/db/development.sqlite3")
      flash[:notice] = 'Successfully imported new raw data directory.'
    rescue Exception => e
      flash[:notice] = "Awfully sorry, this raw data directory could not be imported."
    ensure
      v = nil
    end
    redirect_to root_url
  end

end