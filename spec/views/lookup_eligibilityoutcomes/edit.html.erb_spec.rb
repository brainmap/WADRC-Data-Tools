require 'spec_helper'

describe "lookup_eligibilityoutcomes/edit.html.erb" do
  before(:each) do
    @lookup_eligibilityoutcome = assign(:lookup_eligibilityoutcome, stub_model(LookupEligibilityoutcome,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_eligibilityoutcome form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_eligibilityoutcome_path(@lookup_eligibilityoutcome), :method => "post" do
      assert_select "input#lookup_eligibilityoutcome_description", :name => "lookup_eligibilityoutcome[description]"
    end
  end
end
