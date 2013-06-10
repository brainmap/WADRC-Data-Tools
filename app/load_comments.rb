# encoding: utf-8
require 'radiology_comment'
class LoadComments < ActiveRecord::Base
  # This script will load the radiology_comments rad_path, the comment html, the comment_text, and set the q1_flag
    past_time = Time.new - (1).month
  v_past_date = past_time.strftime("%Y-%m-%d")
  @schedule = Schedule.where("name in ('load_radiology_comment')").first
   @schedulerun = Schedulerun.new
   @schedulerun.schedule_id = @schedule.id
   @schedulerun.comment ="starting load_radiology_comment"
   @schedulerun.save
   @schedulerun.start_time = @schedulerun.created_at
   @schedulerun.save
   v_comment = ""
   begin   # catch all exception and put error in comment
   puts "=============starting path and comments load================================="
    radiology_comments  = RadiologyComment.find(:all)
    
   # radiology_comments[0].  seems to only get the first visit????
    # going off of visit, ok if only called once   
    radiology_comments[0].load_paths(1)
    v_comment = "\n finish load_paths "+v_comment
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
  v_comment = "\n finish load text "+v_comment
   puts "======= finished path and comments load ====="
    @schedulerun.comment =("successful finish load_radiology_comment "+v_comment[0..450])
    @schedulerun.status_flag ="Y"
     @schedulerun.save
     @schedulerun.end_time = @schedulerun.updated_at      
     @schedulerun.save
   rescue Exception => msg
      v_error = msg.to_s
      puts "ERROR !!!!!!!"
      puts v_error
       @schedulerun.comment =v_error[0..499]
       @schedulerun.status_flag="E"
       @schedulerun.save
   end
end