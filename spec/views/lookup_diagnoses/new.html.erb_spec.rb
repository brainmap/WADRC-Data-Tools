require 'spec_helper'

describe "lookup_diagnoses/new.html.erb" do
  before(:each) do
    assign(:lookup_diagnosis, stub_model(LookupDiagnosis,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_diagnosis form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_diagnoses_path, :method => "post" do
      assert_select "input#lookup_diagnosis_description", :name => "lookup_diagnosis[description]"
    end
  end
end
