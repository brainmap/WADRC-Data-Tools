require 'spec_helper'

describe "questionforms/show.html.erb" do
  before(:each) do
    @questionform = assign(:questionform, stub_model(Questionform,
      :description => "Description",
      :long_description => "Long Description",
      :display_order => 1,
      :parent_questionform_id => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Long Description/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
  end
end
