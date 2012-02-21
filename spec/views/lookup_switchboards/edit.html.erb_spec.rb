require 'spec_helper'

describe "lookup_switchboards/edit.html.erb" do
  before(:each) do
    @lookup_switchboard = assign(:lookup_switchboard, stub_model(LookupSwitchboard,
      :description => "MyString",
      :item_number => 1,
      :command => "MyString",
      :argument => "MyString"
    ))
  end

  it "renders the edit lookup_switchboard form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_switchboard_path(@lookup_switchboard), :method => "post" do
      assert_select "input#lookup_switchboard_description", :name => "lookup_switchboard[description]"
      assert_select "input#lookup_switchboard_item_number", :name => "lookup_switchboard[item_number]"
      assert_select "input#lookup_switchboard_command", :name => "lookup_switchboard[command]"
      assert_select "input#lookup_switchboard_argument", :name => "lookup_switchboard[argument]"
    end
  end
end
