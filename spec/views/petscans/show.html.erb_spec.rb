require 'spec_helper'

describe "petscans/show.html.erb" do
  before(:each) do
    @petscan = assign(:petscan, stub_model(Petscan,
      :appointment_id => 1,
      :lookup_pettracer_id => 1,
      :EcatFilename => "Ecat Filename",
      :netinjecteddose => 1.5,
      :units => "Units",
      :range => "Range"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Ecat Filename/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1.5/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Units/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Range/)
  end
end
