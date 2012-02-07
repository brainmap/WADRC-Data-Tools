class RadiologyComment < ActiveRecord::Base
  
  belongs_to :visit 
  

   EXCLUDED_REPORT_ATTRIBUTES = [:rad_path, :q2_flag,:load_date,:created_at, :updated_at, :editable_flag,:rmr_rad, :scan_number_rad]
  acts_as_reportable


  
  # change to text
  def combined_radiology_comments
    var =''
   if !comment_text_1.blank?
     var = var + comment_text_1
   end
  if !comment_text_2.blank?
      var = var + comment_text_2
  end 
  if !comment_text_3.blank?
      var = var + comment_text_3
  end
  if !comment_text_4.blank?
      var = var + comment_text_4
  end
  if !comment_text_5.blank?
      var = var + comment_text_5
  end
    return var
  end
  
  # change to html
  def combined_radiology_comments_html
    var =''
   if !comment_html_1.blank?
     var = var + comment_html_1
   end
  if !comment_html_2.blank?
      var = var + comment_html_2
  end 
  if !comment_html_3.blank?
      var = var + comment_html_3
  end
  if !comment_html_4.blank?
      var = var + comment_html_4
  end
  if !comment_html_5.blank?
      var = var + comment_html_5
  end
    return var
  end  
  
 
end
