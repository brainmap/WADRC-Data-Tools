require 'spec_helper'

describe "medicationdetails/edit.html.erb" do
  before(:each) do
    @medicationdetail = assign(:medicationdetail, stub_model(Medicationdetail,
      :genericname => "MyString",
      :brandname => "MyString",
      :lookup_drugclass_id => 1,
      :prescription => 1,
      :exclusionclass => 1
    ))
  end

  it "renders the edit medicationdetail form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => medicationdetail_path(@medicationdetail), :method => "post" do
      assert_select "input#medicationdetail_genericname", :name => "medicationdetail[genericname]"
      assert_select "input#medicationdetail_brandname", :name => "medicationdetail[brandname]"
      assert_select "input#medicationdetail_lookup_drugclass_id", :name => "medicationdetail[lookup_drugclass_id]"
      assert_select "input#medicationdetail_prescription", :name => "medicationdetail[prescription]"
      assert_select "input#medicationdetail_exclusionclass", :name => "medicationdetail[exclusionclass]"
    end
  end
end
