require 'spec_helper'

describe "radiology_comments/index.html.erb" do
  before(:each) do
    assign(:radiology_comments, [
      stub_model(RadiologyComment,
        :visit_id => "",
        :rmr => "Rmr",
        :scan_number => 1,
        :rmr_rad => "Rmr Rad",
        :scan_number_rad => 1,
        :editable_flag => "Editable Flag",
        :rad_path => "Rad Path",
        :q1_flag => "Q1 Flag",
        :q2_flag => "Q2 Flag",
        :comment_html_1 => "Comment Html 1",
        :comment_html_2 => "Comment Html 2",
        :comment_text_1 => "Comment Text 1",
        :comment_text_2 => "Comment Text 2"
      ),
      stub_model(RadiologyComment,
        :visit_id => "",
        :rmr => "Rmr",
        :scan_number => 1,
        :rmr_rad => "Rmr Rad",
        :scan_number_rad => 1,
        :editable_flag => "Editable Flag",
        :rad_path => "Rad Path",
        :q1_flag => "Q1 Flag",
        :q2_flag => "Q2 Flag",
        :comment_html_1 => "Comment Html 1",
        :comment_html_2 => "Comment Html 2",
        :comment_text_1 => "Comment Text 1",
        :comment_text_2 => "Comment Text 2"
      )
    ])
  end

  it "renders a list of radiology_comments" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Rmr".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Rmr Rad".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Editable Flag".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Rad Path".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Q1 Flag".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Q2 Flag".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Comment Html 1".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Comment Html 2".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Comment Text 1".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Comment Text 2".to_s, :count => 2
  end
end
