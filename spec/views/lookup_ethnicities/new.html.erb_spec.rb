require 'spec_helper'

describe "lookup_ethnicities/new.html.erb" do
  before(:each) do
    assign(:lookup_ethnicity, stub_model(LookupEthnicity,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_ethnicity form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_ethnicities_path, :method => "post" do
      assert_select "input#lookup_ethnicity_description", :name => "lookup_ethnicity[description]"
    end
  end
end
