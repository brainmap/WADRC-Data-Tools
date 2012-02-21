require 'spec_helper'

describe "lookup_cogstatuses/new.html.erb" do
  before(:each) do
    assign(:lookup_cogstatus, stub_model(LookupCogstatus,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_cogstatus form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_cogstatuses_path, :method => "post" do
      assert_select "input#lookup_cogstatus_description", :name => "lookup_cogstatus[description]"
    end
  end
end
