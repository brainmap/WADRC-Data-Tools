require 'spec_helper'

describe "lookup_cogstatuses/index.html.erb" do
  before(:each) do
    assign(:lookup_cogstatuses, [
      stub_model(LookupCogstatus,
        :description => "Description"
      ),
      stub_model(LookupCogstatus,
        :description => "Description"
      )
    ])
  end

  it "renders a list of lookup_cogstatuses" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
