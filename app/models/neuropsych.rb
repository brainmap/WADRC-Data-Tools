class Neuropsych < ActiveRecord::Base
     belongs_to :appointment
     
     def appointment
         @appointment =Appointment.find(self.appointment_id)
         return @appointment
     end
end
