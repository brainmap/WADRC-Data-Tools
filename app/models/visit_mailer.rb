class VisitMailer < ActionMailer::Base
  
  def visit_confirmation(visit, email_params = { :send_to => "ekk@medicine.wisc.edu"}, sent_at = Time.now)
    #raise(LoadError, "Mailer not configured.") unless self.class.configured?

    recipients  email_params[:send_to]
    from        "noreply_johnson_lab@medicine.wisc.edu"
    reply_to    "Erik Kastman <ekk@medicine.wisc.edu>"
    subject     "[Data Panda] New Visit: #{visit.rmr}"
    sent_on sent_at

    # allows access to @message and @sender_name
    # in the view
    body({
      :user => visit.created_by.login, 
      :message => visit.id, 
      :visit_date => visit.date, 
      :visit_path => visit.path,
      :updated_at => visit.updated_at.to_formatted_s(:datetime_daymonthweek), 
      #:enrollment_enum => visit.enrollment.enum,
      :rmr => visit.rmr,
      :image_datasets => visit.image_datasets
    })
  end
  
  def self.configured?
    !ActionMailer::Base.smtp_settings['user_name'].blank? && !ActionMailer::Base.smtp_settings['password']
  end
  
end
