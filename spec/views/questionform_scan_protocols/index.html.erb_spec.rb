require 'spec_helper'

describe "questionform_scan_protocols/index.html.erb" do
  before(:each) do
    assign(:questionform_scan_protocols, [
      stub_model(QuestionformScanProtocol,
        :questionform_id => 1,
        :scan_protocol_id => 1,
        :include_exclude => "Include Exclude"
      ),
      stub_model(QuestionformScanProtocol,
        :questionform_id => 1,
        :scan_protocol_id => 1,
        :include_exclude => "Include Exclude"
      )
    ])
  end

  it "renders a list of questionform_scan_protocols" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Include Exclude".to_s, :count => 2
  end
end
