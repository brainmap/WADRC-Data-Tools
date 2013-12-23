class Tractiontype < ActiveRecord::Base
	belongs_to :trtype
  attr_accessible :description, :display_column_header_1, :display_in_summary, :display_order, :display_summary_column_header_1, :export_column_header_1, :ref_table_a_1, :ref_table_b_1, :status_flag, :triggers_1, :trtype_id, :values_1,:display_search_flag,:form_display_order,:form_display_label,:form_display_field_type,:form_col_span
end
