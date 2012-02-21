require 'spec_helper'

describe "lookup_letterlabels/index.html.erb" do
  before(:each) do
    assign(:lookup_letterlabels, [
      stub_model(LookupLetterlabel,
        :description => "Description",
        :protocol_id => 1,
        :doccategory => 1
      ),
      stub_model(LookupLetterlabel,
        :description => "Description",
        :protocol_id => 1,
        :doccategory => 1
      )
    ])
  end

  it "renders a list of lookup_letterlabels" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
  end
end
