require 'spec_helper'

describe "lookup_drugfreqs/edit.html.erb" do
  before(:each) do
    @lookup_drugfreq = assign(:lookup_drugfreq, stub_model(LookupDrugfreq,
      :frequency => "MyString",
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_drugfreq form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_drugfreq_path(@lookup_drugfreq), :method => "post" do
      assert_select "input#lookup_drugfreq_frequency", :name => "lookup_drugfreq[frequency]"
      assert_select "input#lookup_drugfreq_description", :name => "lookup_drugfreq[description]"
    end
  end
end
