require 'spec_helper'

describe "lookup_famhxes/edit.html.erb" do
  before(:each) do
    @lookup_famhx = assign(:lookup_famhx, stub_model(LookupFamhx,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_famhx form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_famhx_path(@lookup_famhx), :method => "post" do
      assert_select "input#lookup_famhx_description", :name => "lookup_famhx[description]"
    end
  end
end
