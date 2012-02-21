require 'spec_helper'

describe "lookup_pettraces/edit.html.erb" do
  before(:each) do
    @lookup_pettrace = assign(:lookup_pettrace, stub_model(LookupPettrace,
      :name => "MyString",
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_pettrace form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_pettrace_path(@lookup_pettrace), :method => "post" do
      assert_select "input#lookup_pettrace_name", :name => "lookup_pettrace[name]"
      assert_select "input#lookup_pettrace_description", :name => "lookup_pettrace[description]"
    end
  end
end
