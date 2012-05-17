require 'radiology_comment'
class LoadComments < ActiveRecord::Base
  # This script will load the radiology_comments rad_path, the comment html, the comment_text, and set the q1_flag
    past_time = Time.new - (1).month
  v_past_date = past_time.strftime("%Y-%m-%d")
   puts "=============starting path and comments load================================="
    radiology_comments  = RadiologyComment.find(:all)
   # radiology_comments[0].  seems to only get the first visit????
    # going off of visit, ok if only called once   
   radiology_comments[0].load_paths(1)
#   radiology_comments = RadiologyComment.where(" trim(radiology_comments.rad_path) is not null and  (radiology_comments.comment_html_1 is null
#                  OR radiology_comments.comment_header_html_1 is null
#                  OR radiology_comments.visit_id in (select visits.id from visits where visits.date >  '"+v_past_date+"' )  ) " )
#    radiology_comments.each do |rc|
          radiology_comments[0].load_comments(1)
#         rc.load_comments(1)
#     end
     
#     radiology_comments = RadiologyComment.where("comment_html_1 is not null and (comment_text_1 is null or trim(q1_flag) is null or trim(q1_flag) ='' )")
#    radiology_comments.each do |rc|
            radiology_comments[0].load_text
#        rc.load_text
#    end
   puts "======= finished path and comments load ====="
end