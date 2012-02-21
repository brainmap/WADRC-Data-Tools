require 'spec_helper'

describe "lookup_cohorts/index.html.erb" do
  before(:each) do
    assign(:lookup_cohorts, [
      stub_model(LookupCohort,
        :description => "Description"
      ),
      stub_model(LookupCohort,
        :description => "Description"
      )
    ])
  end

  it "renders a list of lookup_cohorts" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
