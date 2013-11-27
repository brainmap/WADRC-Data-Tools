require 'spec_helper'

describe "lookup_consentcohorts/edit.html.erb" do
  before(:each) do
    @lookup_consentcohort = assign(:lookup_consentcohort, stub_model(LookupConsentcohort,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_consentcohort form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_consentcohort_path(@lookup_consentcohort), :method => "post" do
      assert_select "input#lookup_consentcohort_description", :name => "lookup_consentcohort[description]"
    end
  end
end
