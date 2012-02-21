require 'spec_helper'

describe "lookup_eligibility_ineligibilities/new.html.erb" do
  before(:each) do
    assign(:lookup_eligibility_ineligibility, stub_model(LookupEligibilityIneligibility,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_eligibility_ineligibility form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_eligibility_ineligibilities_path, :method => "post" do
      assert_select "input#lookup_eligibility_ineligibility_description", :name => "lookup_eligibility_ineligibility[description]"
    end
  end
end
