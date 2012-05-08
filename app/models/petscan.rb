class Petscan < ActiveRecord::Base
  belongs_to :appointment
  
  # in the db its regular time, but ror converts it to GMT?
  def injecttiontime_utc
    self.injecttiontime.try(:utc)
  end
  
  def scanstarttime_utc
    self.scanstarttime.try(:utc)
  end
end
