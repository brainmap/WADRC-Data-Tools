require 'spec_helper'

describe "radiology_comments/new.html.erb" do
  before(:each) do
    assign(:radiology_comment, stub_model(RadiologyComment,
      :visit_id => "",
      :rmr => "MyString",
      :scan_number => 1,
      :rmr_rad => "MyString",
      :scan_number_rad => 1,
      :editable_flag => "MyString",
      :rad_path => "MyString",
      :q1_flag => "MyString",
      :q2_flag => "MyString",
      :comment_html_1 => "MyString",
      :comment_html_2 => "MyString",
      :comment_text_1 => "MyString",
      :comment_text_2 => "MyString"
    ).as_new_record)
  end

  it "renders new radiology_comment form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => radiology_comments_path, :method => "post" do
      assert_select "input#radiology_comment_visit_id", :name => "radiology_comment[visit_id]"
      assert_select "input#radiology_comment_rmr", :name => "radiology_comment[rmr]"
      assert_select "input#radiology_comment_scan_number", :name => "radiology_comment[scan_number]"
      assert_select "input#radiology_comment_rmr_rad", :name => "radiology_comment[rmr_rad]"
      assert_select "input#radiology_comment_scan_number_rad", :name => "radiology_comment[scan_number_rad]"
      assert_select "input#radiology_comment_editable_flag", :name => "radiology_comment[editable_flag]"
      assert_select "input#radiology_comment_rad_path", :name => "radiology_comment[rad_path]"
      assert_select "input#radiology_comment_q1_flag", :name => "radiology_comment[q1_flag]"
      assert_select "input#radiology_comment_q2_flag", :name => "radiology_comment[q2_flag]"
      assert_select "input#radiology_comment_comment_html_1", :name => "radiology_comment[comment_html_1]"
      assert_select "input#radiology_comment_comment_html_2", :name => "radiology_comment[comment_html_2]"
      assert_select "input#radiology_comment_comment_text_1", :name => "radiology_comment[comment_text_1]"
      assert_select "input#radiology_comment_comment_text_2", :name => "radiology_comment[comment_text_2]"
    end
  end
end
