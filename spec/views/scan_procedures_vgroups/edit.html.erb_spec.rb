require 'spec_helper'

describe "scan_procedures_vgroups/edit.html.erb" do
  before(:each) do
    @scan_procedures_vgroup = assign(:scan_procedures_vgroup, stub_model(ScanProceduresVgroup,
      :scan_procedure_id => 1,
      :vgroup_id => 1
    ))
  end

  it "renders the edit scan_procedures_vgroup form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => scan_procedures_vgroup_path(@scan_procedures_vgroup), :method => "post" do
      assert_select "input#scan_procedures_vgroup_scan_procedure_id", :name => "scan_procedures_vgroup[scan_procedure_id]"
      assert_select "input#scan_procedures_vgroup_vgroup_id", :name => "scan_procedures_vgroup[vgroup_id]"
    end
  end
end
