require 'spec_helper'

describe "lookup_visitfrequencies/show.html.erb" do
  before(:each) do
    @lookup_visitfrequency = assign(:lookup_visitfrequency, stub_model(LookupVisitfrequency,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
