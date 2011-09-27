Clearance.configure do |config|
  config.mailer_sender = 'noreply_johnson_lab@medicine.wisc.edu'
  config.cookie_expiration = lambda { 2.weeks.from_now.utc }
end
