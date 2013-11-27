require 'spec_helper'

describe "lookup_famhxes/new.html.erb" do
  before(:each) do
    assign(:lookup_famhx, stub_model(LookupFamhx,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_famhx form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_famhxes_path, :method => "post" do
      assert_select "input#lookup_famhx_description", :name => "lookup_famhx[description]"
    end
  end
end
