require 'spec_helper'

describe "lookup_visitfrequencies/index.html.erb" do
  before(:each) do
    assign(:lookup_visitfrequencies, [
      stub_model(LookupVisitfrequency,
        :description => "Description"
      ),
      stub_model(LookupVisitfrequency,
        :description => "Description"
      )
    ])
  end

  it "renders a list of lookup_visitfrequencies" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
