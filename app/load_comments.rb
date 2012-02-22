require 'radiology_comment'
class LoadComments < ActiveRecord::Base
  # This script will load the radiology_comments rad_path, the comment html, the comment_text, and set the q1_flag

   puts "=============starting path and comments load================================="
   radiology_comments  = RadiologyComment.find(:all)
   # radiology_comments[0].
   radiology_comments[0].load_paths(1)
    radiology_comments[0].load_comments(1)
    radiology_comments[0].load_text
   puts "======= finished path and comments load ====="
end