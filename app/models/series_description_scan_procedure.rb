class SeriesDescriptionScanProcedure < ActiveRecord::Base
 # attr_accessible :scan_count, :scan_procedure_id, :series_description_id,:scan_count_last_20,:scan_count_last_5,:scan_count_all 
  private
  def series_description_scan_procedure_params
    params.require(:series_description_scan_procedure).permit(:scan_count, :scan_procedure_id, :series_description_id,:scan_count_last_20,:scan_count_last_5,:scan_count_all )
  end
end
