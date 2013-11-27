require 'spec_helper'

describe "lookup_pettraces/new.html.erb" do
  before(:each) do
    assign(:lookup_pettrace, stub_model(LookupPettrace,
      :name => "MyString",
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_pettrace form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_pettraces_path, :method => "post" do
      assert_select "input#lookup_pettrace_name", :name => "lookup_pettrace[name]"
      assert_select "input#lookup_pettrace_description", :name => "lookup_pettrace[description]"
    end
  end
end
