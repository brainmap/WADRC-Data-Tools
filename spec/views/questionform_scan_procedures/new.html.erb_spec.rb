require 'spec_helper'

describe "questionform_scan_procedures/new.html.erb" do
  before(:each) do
    assign(:questionform_scan_procedure, stub_model(QuestionformScanProcedure,
      :questionform_id => 1,
      :scan_procedure_id => 1,
      :include_exclude => "MyString"
    ).as_new_record)
  end

  it "renders new questionform_scan_procedure form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => questionform_scan_procedures_path, :method => "post" do
      assert_select "input#questionform_scan_procedure_questionform_id", :name => "questionform_scan_procedure[questionform_id]"
      assert_select "input#questionform_scan_procedure_scan_procedure_id", :name => "questionform_scan_procedure[scan_procedure_id]"
      assert_select "input#questionform_scan_procedure_include_exclude", :name => "questionform_scan_procedure[include_exclude]"
    end
  end
end
