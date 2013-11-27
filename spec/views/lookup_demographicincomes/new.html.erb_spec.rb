require 'spec_helper'

describe "lookup_demographicincomes/new.html.erb" do
  before(:each) do
    assign(:lookup_demographicincome, stub_model(LookupDemographicincome,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_demographicincome form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_demographicincomes_path, :method => "post" do
      assert_select "input#lookup_demographicincome_description", :name => "lookup_demographicincome[description]"
    end
  end
end
