require 'spec_helper'

describe "medicationdetails/index.html.erb" do
  before(:each) do
    assign(:medicationdetails, [
      stub_model(Medicationdetail,
        :genericname => "Genericname",
        :brandname => "Brandname",
        :lookup_drugclass_id => 1,
        :prescription => 1,
        :exclusionclass => 1
      ),
      stub_model(Medicationdetail,
        :genericname => "Genericname",
        :brandname => "Brandname",
        :lookup_drugclass_id => 1,
        :prescription => 1,
        :exclusionclass => 1
      )
    ])
  end

  it "renders a list of medicationdetails" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Genericname".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Brandname".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
  end
end
