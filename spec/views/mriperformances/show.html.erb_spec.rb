require 'spec_helper'

describe "mriperformances/show.html.erb" do
  before(:each) do
    @mriperformance = assign(:mriperformance, stub_model(Mriperformance,
      :mriscantask_id => 1,
      :hitpercentage => 1.5,
      :accuracypercentage => 1.5
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1.5/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1.5/)
  end
end
