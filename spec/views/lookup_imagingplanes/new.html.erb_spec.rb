require 'spec_helper'

describe "lookup_imagingplanes/new.html.erb" do
  before(:each) do
    assign(:lookup_imagingplane, stub_model(LookupImagingplane,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_imagingplane form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_imagingplanes_path, :method => "post" do
      assert_select "input#lookup_imagingplane_description", :name => "lookup_imagingplane[description]"
    end
  end
end
