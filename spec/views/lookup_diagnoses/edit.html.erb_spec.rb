require 'spec_helper'

describe "lookup_diagnoses/edit.html.erb" do
  before(:each) do
    @lookup_diagnosis = assign(:lookup_diagnosis, stub_model(LookupDiagnosis,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_diagnosis form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_diagnosis_path(@lookup_diagnosis), :method => "post" do
      assert_select "input#lookup_diagnosis_description", :name => "lookup_diagnosis[description]"
    end
  end
end
