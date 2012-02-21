require 'spec_helper'

describe "lookup_genders/new.html.erb" do
  before(:each) do
    assign(:lookup_gender, stub_model(LookupGender,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_gender form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_genders_path, :method => "post" do
      assert_select "input#lookup_gender_description", :name => "lookup_gender[description]"
    end
  end
end
