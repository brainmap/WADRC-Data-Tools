require 'spec_helper'

describe "lookup_letterlabels/show.html.erb" do
  before(:each) do
    @lookup_letterlabel = assign(:lookup_letterlabel, stub_model(LookupLetterlabel,
      :description => "Description",
      :protocol_id => 1,
      :doccategory => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
  end
end
