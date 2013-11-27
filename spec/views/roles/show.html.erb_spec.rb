require 'spec_helper'

describe "roles/show.html.erb" do
  before(:each) do
    @role = assign(:role, stub_model(Role,
      :role => "Role",
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Role/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
