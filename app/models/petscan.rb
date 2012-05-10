class Petscan < ActiveRecord::Base
  belongs_to :appointment
  
  default_scope :order => 'appointment_id DESC'
  
  def appointment
      @appointment =Appointment.find(self.appointment_id)
      return @appointment
  end
  
  def petscan_appointment_date
      @appointment =Appointment.find(self.appointment_id)
      return @appointment.appointment_date
  end
  # how to order by the appointment_date????? 
  # in the db its regular time, but ror converts it to GMT?  --- actually utc in the database -- add 6 or 5 hours to the access db time during import to msql
#  def injecttiontime_utc
#    self.injecttiontime.try(:utc)
#  end
  
#  def scanstarttime_utc
#    self.scanstarttime.try(:utc)
#  end
end
