require 'spec_helper'

describe "lookup_eligibilityoutcomes/new.html.erb" do
  before(:each) do
    assign(:lookup_eligibilityoutcome, stub_model(LookupEligibilityoutcome,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_eligibilityoutcome form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_eligibilityoutcomes_path, :method => "post" do
      assert_select "input#lookup_eligibilityoutcome_description", :name => "lookup_eligibilityoutcome[description]"
    end
  end
end
