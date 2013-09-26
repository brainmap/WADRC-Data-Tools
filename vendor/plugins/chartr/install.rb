require 'chartrfiles'

# Workaround a problem with script/plugin and http-based repos.
# See http://dev.rubyonrails.org/ticket/8189
Dir.chdir(Dir.getwd.sub(/vendor.*/, '')) do

  ##
  ## Copy over asset files (javascript/css/images) from the plugin
  ## directory to public/
  ##

  # destination = RAILS_ROOT + "/public/javascripts/chartr"
  destination = Rails.root + "/public/javascripts/chartr"

  # Create destination directory (RAILS_ROOT/public/javascripts/chartr)
  ####### HASHING OUT ### FileUtils.mkdir_p(destination)

  # Copy each file to the destination directory
  ChartrFiles.each do |f|
    # FileUtils.cp_r(f, destination)
  end
end
