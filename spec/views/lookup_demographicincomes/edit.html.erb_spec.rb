require 'spec_helper'

describe "lookup_demographicincomes/edit.html.erb" do
  before(:each) do
    @lookup_demographicincome = assign(:lookup_demographicincome, stub_model(LookupDemographicincome,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_demographicincome form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_demographicincome_path(@lookup_demographicincome), :method => "post" do
      assert_select "input#lookup_demographicincome_description", :name => "lookup_demographicincome[description]"
    end
  end
end
