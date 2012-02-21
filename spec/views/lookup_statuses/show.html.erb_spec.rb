require 'spec_helper'

describe "lookup_statuses/show.html.erb" do
  before(:each) do
    @lookup_status = assign(:lookup_status, stub_model(LookupStatus,
      :description => "Description",
      :status_type => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
  end
end
