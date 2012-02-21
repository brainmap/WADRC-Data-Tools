require 'spec_helper'

describe "lookup_recruitsources/edit.html.erb" do
  before(:each) do
    @lookup_recruitsource = assign(:lookup_recruitsource, stub_model(LookupRecruitsource,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_recruitsource form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_recruitsource_path(@lookup_recruitsource), :method => "post" do
      assert_select "input#lookup_recruitsource_description", :name => "lookup_recruitsource[description]"
    end
  end
end
