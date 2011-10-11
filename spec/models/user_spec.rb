# require 'spec_helper'
# 
# describe User do
#   it "should authenticate with matching username and password" do
#     user = Factory(:user, :login => 'admin', :password => 'secret')
#     User.authenticate('admin', 'secret').should == user
#   end
#   
#   it "should not authenticate with incorrect password" do
#     user = Factory(:user, :login => 'admin', :password => 'secret')
#     User.authenticate('admin', 'incorrect').should be_nil
#   end
# end