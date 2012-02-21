require 'spec_helper'

describe "radiology_comments/show.html.erb" do
  before(:each) do
    @radiology_comment = assign(:radiology_comment, stub_model(RadiologyComment,
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
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(//)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Rmr/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Rmr Rad/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Editable Flag/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Rad Path/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Q1 Flag/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Q2 Flag/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Comment Html 1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Comment Html 2/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Comment Text 1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Comment Text 2/)
  end
end
