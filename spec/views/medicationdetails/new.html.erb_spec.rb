require 'spec_helper'

describe "medicationdetails/new.html.erb" do
  before(:each) do
    assign(:medicationdetail, stub_model(Medicationdetail,
      :genericname => "MyString",
      :brandname => "MyString",
      :lookup_drugclass_id => 1,
      :prescription => 1,
      :exclusionclass => 1
    ).as_new_record)
  end

  it "renders new medicationdetail form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => medicationdetails_path, :method => "post" do
      assert_select "input#medicationdetail_genericname", :name => "medicationdetail[genericname]"
      assert_select "input#medicationdetail_brandname", :name => "medicationdetail[brandname]"
      assert_select "input#medicationdetail_lookup_drugclass_id", :name => "medicationdetail[lookup_drugclass_id]"
      assert_select "input#medicationdetail_prescription", :name => "medicationdetail[prescription]"
      assert_select "input#medicationdetail_exclusionclass", :name => "medicationdetail[exclusionclass]"
    end
  end
end
