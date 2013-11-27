require 'spec_helper'

describe "lookup_consentcohorts/new.html.erb" do
  before(:each) do
    assign(:lookup_consentcohort, stub_model(LookupConsentcohort,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_consentcohort form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_consentcohorts_path, :method => "post" do
      assert_select "input#lookup_consentcohort_description", :name => "lookup_consentcohort[description]"
    end
  end
end
