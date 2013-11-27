require 'spec_helper'

describe "question_scan_procedures/new.html.erb" do
  before(:each) do
    assign(:question_scan_procedure, stub_model(QuestionScanProcedure,
      :question_id => 1,
      :scan_procedure_id => 1,
      :include_exclude => "MyString"
    ).as_new_record)
  end

  it "renders new question_scan_procedure form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => question_scan_procedures_path, :method => "post" do
      assert_select "input#question_scan_procedure_question_id", :name => "question_scan_procedure[question_id]"
      assert_select "input#question_scan_procedure_scan_procedure_id", :name => "question_scan_procedure[scan_procedure_id]"
      assert_select "input#question_scan_procedure_include_exclude", :name => "question_scan_procedure[include_exclude]"
    end
  end
end
