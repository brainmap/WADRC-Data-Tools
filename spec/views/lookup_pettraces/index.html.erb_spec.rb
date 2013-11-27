require 'spec_helper'

describe "lookup_pettraces/index.html.erb" do
  before(:each) do
    assign(:lookup_pettraces, [
      stub_model(LookupPettrace,
        :name => "Name",
        :description => "Description"
      ),
      stub_model(LookupPettrace,
        :name => "Name",
        :description => "Description"
      )
    ])
  end

  it "renders a list of lookup_pettraces" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
