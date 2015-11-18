class SeriesDescriptionScanProcedure < ActiveRecord::Base
  attr_accessible :scan_count, :scan_procedure_id, :series_description_id,:scan_count_last_20,:scan_count_last_5,:scan_count_all
end
