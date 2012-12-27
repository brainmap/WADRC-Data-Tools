require 'spec_helper'

describe "scan_procedures_vgroups/show.html.erb" do
  before(:each) do
    @scan_procedures_vgroup = assign(:scan_procedures_vgroup, stub_model(ScanProceduresVgroup,
      :scan_procedure_id => 1,
      :vgroup_id => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
  end
end
