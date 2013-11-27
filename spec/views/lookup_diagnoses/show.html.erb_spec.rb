require 'spec_helper'

describe "lookup_diagnoses/show.html.erb" do
  before(:each) do
    @lookup_diagnosis = assign(:lookup_diagnosis, stub_model(LookupDiagnosis,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
