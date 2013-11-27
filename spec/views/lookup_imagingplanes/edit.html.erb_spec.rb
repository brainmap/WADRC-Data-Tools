require 'spec_helper'

describe "lookup_imagingplanes/edit.html.erb" do
  before(:each) do
    @lookup_imagingplane = assign(:lookup_imagingplane, stub_model(LookupImagingplane,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_imagingplane form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_imagingplane_path(@lookup_imagingplane), :method => "post" do
      assert_select "input#lookup_imagingplane_description", :name => "lookup_imagingplane[description]"
    end
  end
end
