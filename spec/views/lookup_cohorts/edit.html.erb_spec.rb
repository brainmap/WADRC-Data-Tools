require 'spec_helper'

describe "lookup_cohorts/edit.html.erb" do
  before(:each) do
    @lookup_cohort = assign(:lookup_cohort, stub_model(LookupCohort,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_cohort form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_cohort_path(@lookup_cohort), :method => "post" do
      assert_select "input#lookup_cohort_description", :name => "lookup_cohort[description]"
    end
  end
end
