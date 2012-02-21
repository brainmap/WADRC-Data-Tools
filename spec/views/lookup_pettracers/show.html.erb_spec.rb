require 'spec_helper'

describe "lookup_pettracers/show.html.erb" do
  before(:each) do
    @lookup_pettracer = assign(:lookup_pettracer, stub_model(LookupPettracer,
      :name => "Name",
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
