class Blooddraw < ActiveRecord::Base
  
  belongs_to :appointment
  
  default_scope :order => 'appointment_id DESC'
  
  def appointment
      @appointment =Appointment.find(self.appointment_id)
      return @appointment
  end
  
  def blooddraw_appointment_date
      @appointment =Appointment.find(self.appointment_id)
      return @appointment.appointment_date
  end
end
