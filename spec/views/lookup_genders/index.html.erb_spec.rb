require 'spec_helper'

describe "lookup_genders/index.html.erb" do
  before(:each) do
    assign(:lookup_genders, [
      stub_model(LookupGender,
        :description => "Description"
      ),
      stub_model(LookupGender,
        :description => "Description"
      )
    ])
  end

  it "renders a list of lookup_genders" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
