require 'spec_helper'

describe "lookup_sets/new.html.erb" do
  before(:each) do
    assign(:lookup_set, stub_model(LookupSet,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_set form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_sets_path, :method => "post" do
      assert_select "input#lookup_set_description", :name => "lookup_set[description]"
    end
  end
end
