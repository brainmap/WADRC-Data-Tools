# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
WADRCDataTools::Application.initialize!

require 'ruport/acts_as_reportable'