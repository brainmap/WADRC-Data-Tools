require 'spec_helper'

describe "lookup_genders/show.html.erb" do
  before(:each) do
    @lookup_gender = assign(:lookup_gender, stub_model(LookupGender,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
