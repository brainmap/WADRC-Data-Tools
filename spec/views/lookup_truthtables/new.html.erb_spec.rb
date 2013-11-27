require 'spec_helper'

describe "lookup_truthtables/new.html.erb" do
  before(:each) do
    assign(:lookup_truthtable, stub_model(LookupTruthtable,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_truthtable form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_truthtables_path, :method => "post" do
      assert_select "input#lookup_truthtable_description", :name => "lookup_truthtable[description]"
    end
  end
end
