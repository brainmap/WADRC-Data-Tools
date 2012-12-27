require 'spec_helper'

describe "scan_procedures_vgroups/index.html.erb" do
  before(:each) do
    assign(:scan_procedures_vgroups, [
      stub_model(ScanProceduresVgroup,
        :scan_procedure_id => 1,
        :vgroup_id => 1
      ),
      stub_model(ScanProceduresVgroup,
        :scan_procedure_id => 1,
        :vgroup_id => 1
      )
    ])
  end

  it "renders a list of scan_procedures_vgroups" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
  end
end
