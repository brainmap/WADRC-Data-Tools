require 'spec_helper'

describe "lookup_cohorts/new.html.erb" do
  before(:each) do
    assign(:lookup_cohort, stub_model(LookupCohort,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_cohort form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_cohorts_path, :method => "post" do
      assert_select "input#lookup_cohort_description", :name => "lookup_cohort[description]"
    end
  end
end
