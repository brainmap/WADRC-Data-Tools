##
## Constants
##

##
## Load the library
##
require 'chartr'
require 'helpers/chartr_helpers'

##
## Inject includes for Chartr libraries
##
ActionView::Base.send(:include, ActionView::Helpers::ChartrHelpers)
