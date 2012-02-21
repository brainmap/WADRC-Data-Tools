require 'spec_helper'

describe "lookup_relationships/edit.html.erb" do
  before(:each) do
    @lookup_relationship = assign(:lookup_relationship, stub_model(LookupRelationship,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_relationship form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_relationship_path(@lookup_relationship), :method => "post" do
      assert_select "input#lookup_relationship_description", :name => "lookup_relationship[description]"
    end
  end
end
