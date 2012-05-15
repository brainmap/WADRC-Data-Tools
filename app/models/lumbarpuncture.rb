class Lumbarpuncture < ActiveRecord::Base
    belongs_to :appointment
    
    has_many :lumbarpuncture_results,:dependent => :destroy
    accepts_nested_attributes_for :lumbarpuncture_results, :reject_if => :all_blank, :allow_destroy => true
    
    def appointment
        @appointment =Appointment.find(self.appointment_id)
        return @appointment
    end
end
