require 'spec_helper'

describe "lookup_genders/edit.html.erb" do
  before(:each) do
    @lookup_gender = assign(:lookup_gender, stub_model(LookupGender,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_gender form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_gender_path(@lookup_gender), :method => "post" do
      assert_select "input#lookup_gender_description", :name => "lookup_gender[description]"
    end
  end
end
