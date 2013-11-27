require 'spec_helper'

describe "mriperformances/edit.html.erb" do
  before(:each) do
    @mriperformance = assign(:mriperformance, stub_model(Mriperformance,
      :mriscantask_id => 1,
      :hitpercentage => 1.5,
      :accuracypercentage => 1.5
    ))
  end

  it "renders the edit mriperformance form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => mriperformance_path(@mriperformance), :method => "post" do
      assert_select "input#mriperformance_mriscantask_id", :name => "mriperformance[mriscantask_id]"
      assert_select "input#mriperformance_hitpercentage", :name => "mriperformance[hitpercentage]"
      assert_select "input#mriperformance_accuracypercentage", :name => "mriperformance[accuracypercentage]"
    end
  end
end
