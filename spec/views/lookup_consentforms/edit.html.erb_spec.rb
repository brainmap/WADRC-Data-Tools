require 'spec_helper'

describe "lookup_consentforms/edit.html.erb" do
  before(:each) do
    @lookup_consentform = assign(:lookup_consentform, stub_model(LookupConsentform,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_consentform form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_consentform_path(@lookup_consentform), :method => "post" do
      assert_select "input#lookup_consentform_description", :name => "lookup_consentform[description]"
    end
  end
end
