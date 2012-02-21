require 'spec_helper'

describe "lookup_relationships/new.html.erb" do
  before(:each) do
    assign(:lookup_relationship, stub_model(LookupRelationship,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_relationship form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_relationships_path, :method => "post" do
      assert_select "input#lookup_relationship_description", :name => "lookup_relationship[description]"
    end
  end
end
