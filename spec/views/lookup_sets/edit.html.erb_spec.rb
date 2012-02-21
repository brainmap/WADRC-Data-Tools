require 'spec_helper'

describe "lookup_sets/edit.html.erb" do
  before(:each) do
    @lookup_set = assign(:lookup_set, stub_model(LookupSet,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_set form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_set_path(@lookup_set), :method => "post" do
      assert_select "input#lookup_set_description", :name => "lookup_set[description]"
    end
  end
end
