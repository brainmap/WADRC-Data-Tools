require 'spec_helper'

describe "questionforms/edit.html.erb" do
  before(:each) do
    @questionform = assign(:questionform, stub_model(Questionform,
      :description => "MyString",
      :long_description => "MyString",
      :display_order => 1,
      :parent_questionform_id => 1
    ))
  end

  it "renders the edit questionform form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => questionform_path(@questionform), :method => "post" do
      assert_select "input#questionform_description", :name => "questionform[description]"
      assert_select "input#questionform_long_description", :name => "questionform[long_description]"
      assert_select "input#questionform_display_order", :name => "questionform[display_order]"
      assert_select "input#questionform_parent_questionform_id", :name => "questionform[parent_questionform_id]"
    end
  end
end
