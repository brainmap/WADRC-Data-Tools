class RawDataImportsController < ApplicationController
  
  def new
    @recent_visits = Visit.find(:all, :conditions => ['created_at > ?', 1.month.ago]).reverse
    
    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  def create
    @visit_directory_to_scan = params[:raw_data_import][:directory].chomp(' ')
    if validates_truthiness_of_directory(@visit_directory_to_scan)
      v = VisitRawDataDirectory.new(@visit_directory_to_scan, params[:raw_data_import][:scan_procedure])
      puts "Current User: ", `whoami`
      puts "+++ Importing #{v.visit_directory} as part of #{v.scan_procedure_name} +++"
      begin
        v.scan
      rescue Exception => e
        v = nil
        flash[:error] = "Awfully sorry, this raw data directory could not be scanned. #{e}"
      end
      unless v.nil?
        @visit = Visit.create_or_update_from_metamri(v, created_by = current_user)
        unless @visit.new_record?
          flash[:notice] = "Sucessfully imported raw data directory."
          VisitMailer.deliver_visit_confirmation(@visit, {:send_to => "erik.kastman@gmail.com" })
        else
          flash[:error] = "Awfully sorry, this raw data directory could not be saved to the database."
        end
      end
      redirect_to root_url
    else
      flash[:error] = "Invalid raw data directory, please check your path and try again."
      redirect_to new_raw_data_import_path
    end
  end
  
  def validates_truthiness_of_directory(dir)
    dir =~ /Data\/vtrak1\/raw\//
  end

end