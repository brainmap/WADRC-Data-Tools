require 'spec_helper'

describe "lookup_sources/edit.html.erb" do
  before(:each) do
    @lookup_source = assign(:lookup_source, stub_model(LookupSource,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_source form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_source_path(@lookup_source), :method => "post" do
      assert_select "input#lookup_source_description", :name => "lookup_source[description]"
    end
  end
end
