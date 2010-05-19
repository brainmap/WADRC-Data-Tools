class VisitMailer < ActionMailer::Base
  
  def visit_confirmation(visit, email_params = { :send_to => "noreply_johnson_lab@medicine.wisc.edu"}, sent_at = Time.now)
    raise(LoadError, "Unable to send to external email addresses without email credentials.") if !email_params[:send_to].ends_with?('@medicine.wisc.edu') unless self.class.smtp_credentialed?

    # Set Email Params
    recipients  email_params[:send_to]
    from        "noreply_johnson_lab@medicine.wisc.edu"
    reply_to    "Erik Kastman <ekk@medicine.wisc.edu>"
    subject     "[Data Panda] New Visit: #{visit.rmr}"
    sent_on sent_at

    # Required Body Params
    body_params = {
      :message => visit.id, 
      :visit_date => visit.date, 
      :visit_path => visit.path,
      :updated_at => visit.updated_at.to_formatted_s(:datetime_daymonthweek), 
      :rmr => visit.rmr,
      :image_datasets => visit.image_datasets      
    }
    
    # Optional Body Params
    body_params['user'] = visit.created_by.login if visit.created_by
    body_params['enrollment_enumber'] = visit.enrollment.enumber if visit.enrollment
    
    # Set Body Params
    body(body_params)
  end
  
  def self.smtp_credentialed?
    !ActionMailer::Base.smtp_settings[:user_name].blank? && !ActionMailer::Base.smtp_settings[:password].blank?
  end
  
end
