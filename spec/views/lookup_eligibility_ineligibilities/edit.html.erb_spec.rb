require 'spec_helper'

describe "lookup_eligibility_ineligibilities/edit.html.erb" do
  before(:each) do
    @lookup_eligibility_ineligibility = assign(:lookup_eligibility_ineligibility, stub_model(LookupEligibilityIneligibility,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_eligibility_ineligibility form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_eligibility_ineligibility_path(@lookup_eligibility_ineligibility), :method => "post" do
      assert_select "input#lookup_eligibility_ineligibility_description", :name => "lookup_eligibility_ineligibility[description]"
    end
  end
end
