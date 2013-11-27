require 'spec_helper'

describe "scan_procedures_vgroups/new.html.erb" do
  before(:each) do
    assign(:scan_procedures_vgroup, stub_model(ScanProceduresVgroup,
      :scan_procedure_id => 1,
      :vgroup_id => 1
    ).as_new_record)
  end

  it "renders new scan_procedures_vgroup form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => scan_procedures_vgroups_path, :method => "post" do
      assert_select "input#scan_procedures_vgroup_scan_procedure_id", :name => "scan_procedures_vgroup[scan_procedure_id]"
      assert_select "input#scan_procedures_vgroup_vgroup_id", :name => "scan_procedures_vgroup[vgroup_id]"
    end
  end
end
