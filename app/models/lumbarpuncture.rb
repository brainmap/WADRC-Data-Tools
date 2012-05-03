class Lumbarpuncture < ActiveRecord::Base
    belongs_to :appointment
    
    has_many :lumbarpuncture_results,:dependent => :destroy
end
