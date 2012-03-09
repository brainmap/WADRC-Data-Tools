require 'spec_helper'

describe "question_scan_protocols/new.html.erb" do
  before(:each) do
    assign(:question_scan_protocol, stub_model(QuestionScanProtocol,
      :question_id => 1,
      :scan_protocol_id => 1,
      :include_exclude => "MyString"
    ).as_new_record)
  end

  it "renders new question_scan_protocol form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => question_scan_protocols_path, :method => "post" do
      assert_select "input#question_scan_protocol_question_id", :name => "question_scan_protocol[question_id]"
      assert_select "input#question_scan_protocol_scan_protocol_id", :name => "question_scan_protocol[scan_protocol_id]"
      assert_select "input#question_scan_protocol_include_exclude", :name => "question_scan_protocol[include_exclude]"
    end
  end
end
