##
## Delete public asset files
##

require 'fileutils'

installed_files = RAILS_ROOT + "/public/javascripts/chartr"

# Delete installed javascript files
FileUtils.rm_r(installed_files)