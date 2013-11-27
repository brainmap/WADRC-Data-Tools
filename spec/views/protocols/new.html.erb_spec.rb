require 'spec_helper'

describe "protocols/new.html.erb" do
  before(:each) do
    assign(:protocol, stub_model(Protocol,
      :name => "MyString",
      :abbr => "MyString",
      :path => "MyString",
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new protocol form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => protocols_path, :method => "post" do
      assert_select "input#protocol_name", :name => "protocol[name]"
      assert_select "input#protocol_abbr", :name => "protocol[abbr]"
      assert_select "input#protocol_path", :name => "protocol[path]"
      assert_select "input#protocol_description", :name => "protocol[description]"
    end
  end
end
