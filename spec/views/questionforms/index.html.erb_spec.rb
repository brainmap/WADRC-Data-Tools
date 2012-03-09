require 'spec_helper'

describe "questionforms/index.html.erb" do
  before(:each) do
    assign(:questionforms, [
      stub_model(Questionform,
        :description => "Description",
        :long_description => "Long Description",
        :display_order => 1,
        :parent_questionform_id => 1
      ),
      stub_model(Questionform,
        :description => "Description",
        :long_description => "Long Description",
        :display_order => 1,
        :parent_questionform_id => 1
      )
    ])
  end

  it "renders a list of questionforms" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Long Description".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
  end
end
