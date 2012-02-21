require 'spec_helper'

describe "lookup_recruitsources/new.html.erb" do
  before(:each) do
    assign(:lookup_recruitsource, stub_model(LookupRecruitsource,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_recruitsource form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_recruitsources_path, :method => "post" do
      assert_select "input#lookup_recruitsource_description", :name => "lookup_recruitsource[description]"
    end
  end
end
