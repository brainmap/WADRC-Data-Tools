require 'spec_helper'

describe "lookup_truthtables/index.html.erb" do
  before(:each) do
    assign(:lookup_truthtables, [
      stub_model(LookupTruthtable,
        :description => "Description"
      ),
      stub_model(LookupTruthtable,
        :description => "Description"
      )
    ])
  end

  it "renders a list of lookup_truthtables" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
