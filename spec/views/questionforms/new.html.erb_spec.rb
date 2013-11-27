require 'spec_helper'

describe "questionforms/new.html.erb" do
  before(:each) do
    assign(:questionform, stub_model(Questionform,
      :description => "MyString",
      :long_description => "MyString",
      :display_order => 1,
      :parent_questionform_id => 1
    ).as_new_record)
  end

  it "renders new questionform form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => questionforms_path, :method => "post" do
      assert_select "input#questionform_description", :name => "questionform[description]"
      assert_select "input#questionform_long_description", :name => "questionform[long_description]"
      assert_select "input#questionform_display_order", :name => "questionform[display_order]"
      assert_select "input#questionform_parent_questionform_id", :name => "questionform[parent_questionform_id]"
    end
  end
end
