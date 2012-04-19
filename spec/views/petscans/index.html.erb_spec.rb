require 'spec_helper'

describe "petscans/index.html.erb" do
  before(:each) do
    assign(:petscans, [
      stub_model(Petscan,
        :appointment_id => 1,
        :lookup_pettracer_id => 1,
        :EcatFilename => "Ecat Filename",
        :netinjecteddose => 1.5,
        :units => "Units",
        :range => "Range"
      ),
      stub_model(Petscan,
        :appointment_id => 1,
        :lookup_pettracer_id => 1,
        :EcatFilename => "Ecat Filename",
        :netinjecteddose => 1.5,
        :units => "Units",
        :range => "Range"
      )
    ])
  end

  it "renders a list of petscans" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Ecat Filename".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.5.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Units".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Range".to_s, :count => 2
  end
end
