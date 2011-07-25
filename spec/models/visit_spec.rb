require 'spec_helper'

describe Visit do
  it "should update compiled_at if compiled_folder changed." do
    Timecop.freeze
    visit = Factory(:visit, :compile_folder => "no")
    visit.compile_folder = "yes"
    visit.save
    visit.compiled_at.should == Time.zone.now
  end
  
  it "should not update compiled_at if compiled_folder didn't change." do
    Timecop.freeze
    visit = Factory(:visit)
    visit.save
    visit.compiled_at.should_not == Time.zone.now
  end
end