class CgTableType < ActiveRecord::Base
  #attr_accessible :description, :protocol_id, :table_type, :status_flag   
  
  private
  def cg_table_type_params
    params.require(:cg_table_type).permit(:description, :protocol_id, :table_type, :status_flag )
  end
end
