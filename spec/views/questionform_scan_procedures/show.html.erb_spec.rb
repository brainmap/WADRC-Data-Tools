require 'spec_helper'

describe "questionform_scan_procedures/show.html.erb" do
  before(:each) do
    @questionform_scan_procedure = assign(:questionform_scan_procedure, stub_model(QuestionformScanProcedure,
      :questionform_id => 1,
      :scan_procedure_id => 1,
      :include_exclude => "Include Exclude"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Include Exclude/)
  end
end
