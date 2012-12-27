require 'spec_helper'

describe "mriperformances/index.html.erb" do
  before(:each) do
    assign(:mriperformances, [
      stub_model(Mriperformance,
        :mriscantask_id => 1,
        :hitpercentage => 1.5,
        :accuracypercentage => 1.5
      ),
      stub_model(Mriperformance,
        :mriscantask_id => 1,
        :hitpercentage => 1.5,
        :accuracypercentage => 1.5
      )
    ])
  end

  it "renders a list of mriperformances" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.5.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.5.to_s, :count => 2
  end
end
