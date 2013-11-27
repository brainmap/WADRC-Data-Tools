require 'spec_helper'

describe "lookup_consentforms/new.html.erb" do
  before(:each) do
    assign(:lookup_consentform, stub_model(LookupConsentform,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_consentform form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_consentforms_path, :method => "post" do
      assert_select "input#lookup_consentform_description", :name => "lookup_consentform[description]"
    end
  end
end
