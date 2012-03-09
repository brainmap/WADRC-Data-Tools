require 'spec_helper'

describe "question_scan_procedures/show.html.erb" do
  before(:each) do
    @question_scan_procedure = assign(:question_scan_procedure, stub_model(QuestionScanProcedure,
      :question_id => 1,
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
