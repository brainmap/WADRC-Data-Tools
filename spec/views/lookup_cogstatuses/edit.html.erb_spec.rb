require 'spec_helper'

describe "lookup_cogstatuses/edit.html.erb" do
  before(:each) do
    @lookup_cogstatus = assign(:lookup_cogstatus, stub_model(LookupCogstatus,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_cogstatus form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_cogstatus_path(@lookup_cogstatus), :method => "post" do
      assert_select "input#lookup_cogstatus_description", :name => "lookup_cogstatus[description]"
    end
  end
end
