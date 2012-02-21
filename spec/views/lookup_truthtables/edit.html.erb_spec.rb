require 'spec_helper'

describe "lookup_truthtables/edit.html.erb" do
  before(:each) do
    @lookup_truthtable = assign(:lookup_truthtable, stub_model(LookupTruthtable,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_truthtable form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_truthtable_path(@lookup_truthtable), :method => "post" do
      assert_select "input#lookup_truthtable_description", :name => "lookup_truthtable[description]"
    end
  end
end
