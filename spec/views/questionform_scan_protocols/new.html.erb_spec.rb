require 'spec_helper'

describe "questionform_scan_protocols/new.html.erb" do
  before(:each) do
    assign(:questionform_scan_protocol, stub_model(QuestionformScanProtocol,
      :questionform_id => 1,
      :scan_protocol_id => 1,
      :include_exclude => "MyString"
    ).as_new_record)
  end

  it "renders new questionform_scan_protocol form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => questionform_scan_protocols_path, :method => "post" do
      assert_select "input#questionform_scan_protocol_questionform_id", :name => "questionform_scan_protocol[questionform_id]"
      assert_select "input#questionform_scan_protocol_scan_protocol_id", :name => "questionform_scan_protocol[scan_protocol_id]"
      assert_select "input#questionform_scan_protocol_include_exclude", :name => "questionform_scan_protocol[include_exclude]"
    end
  end
end
