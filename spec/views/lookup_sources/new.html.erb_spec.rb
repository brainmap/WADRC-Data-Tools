require 'spec_helper'

describe "lookup_sources/new.html.erb" do
  before(:each) do
    assign(:lookup_source, stub_model(LookupSource,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_source form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_sources_path, :method => "post" do
      assert_select "input#lookup_source_description", :name => "lookup_source[description]"
    end
  end
end
