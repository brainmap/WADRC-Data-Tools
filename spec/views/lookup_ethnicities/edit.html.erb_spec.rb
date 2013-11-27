require 'spec_helper'

describe "lookup_ethnicities/edit.html.erb" do
  before(:each) do
    @lookup_ethnicity = assign(:lookup_ethnicity, stub_model(LookupEthnicity,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_ethnicity form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_ethnicity_path(@lookup_ethnicity), :method => "post" do
      assert_select "input#lookup_ethnicity_description", :name => "lookup_ethnicity[description]"
    end
  end
end
