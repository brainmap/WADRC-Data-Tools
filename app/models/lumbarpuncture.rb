class Lumbarpuncture < ActiveRecord::Base
    belongs_to :appointment
    
    has_many :lumbarpuncture_results,:dependent => :destroy
    
    def appointment
        @appointment =Appointment.find(self.appointment_id)
        return @appointment
    end
end
