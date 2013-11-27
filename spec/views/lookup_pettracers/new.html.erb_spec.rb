require 'spec_helper'

describe "lookup_pettracers/new.html.erb" do
  before(:each) do
    assign(:lookup_pettracer, stub_model(LookupPettracer,
      :name => "MyString",
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_pettracer form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_pettracers_path, :method => "post" do
      assert_select "input#lookup_pettracer_name", :name => "lookup_pettracer[name]"
      assert_select "input#lookup_pettracer_description", :name => "lookup_pettracer[description]"
    end
  end
end
