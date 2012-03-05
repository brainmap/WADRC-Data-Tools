require 'spec_helper'

describe "lookup_refs/new.html.erb" do
  before(:each) do
    assign(:lookup_ref, stub_model(LookupRef,
      :ref_value => 1,
      :description => "MyString",
      :display_order => 1,
      :label => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_ref form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_refs_path, :method => "post" do
      assert_select "input#lookup_ref_ref_value", :name => "lookup_ref[ref_value]"
      assert_select "input#lookup_ref_description", :name => "lookup_ref[description]"
      assert_select "input#lookup_ref_display_order", :name => "lookup_ref[display_order]"
      assert_select "input#lookup_ref_label", :name => "lookup_ref[label]"
    end
  end
end
