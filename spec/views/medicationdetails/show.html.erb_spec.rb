require 'spec_helper'

describe "medicationdetails/show.html.erb" do
  before(:each) do
    @medicationdetail = assign(:medicationdetail, stub_model(Medicationdetail,
      :genericname => "Genericname",
      :brandname => "Brandname",
      :lookup_drugclass_id => 1,
      :prescription => 1,
      :exclusionclass => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Genericname/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Brandname/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
  end
end
