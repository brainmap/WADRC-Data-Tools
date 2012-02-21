require 'spec_helper'

describe "lookup_drugclasses/index.html.erb" do
  before(:each) do
    assign(:lookup_drugclasses, [
      stub_model(LookupDrugclass,
        :epodrugclass => "Epodrugclass",
        :description => "Description"
      ),
      stub_model(LookupDrugclass,
        :epodrugclass => "Epodrugclass",
        :description => "Description"
      )
    ])
  end

  it "renders a list of lookup_drugclasses" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Epodrugclass".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
