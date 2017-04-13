# encoding: utf-8
class AuthorizedController < ApplicationController
   # need to skip if json and search and path_contains -- set a userid
  before_action :authenticate_user!
#  check_authorization
#   load_and_authorize_resource
load_resource


end