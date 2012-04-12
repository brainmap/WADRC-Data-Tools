require 'spec_helper'

describe "vgroups/index.html.erb" do
  before(:each) do
    assign(:vgroups, [
      stub_model(Vgroup,
        :participant_id => 1,
        :note => "Note",
        :transfer_mri => "Transfer Mri",
        :transfer_pet => "Transfer Pet",
        :blood_draw => "Blood Draw",
        :np_testing => "Np Testing",
        :lumbar_punture => "Lumbar Punture"
      ),
      stub_model(Vgroup,
        :participant_id => 1,
        :note => "Note",
        :transfer_mri => "Transfer Mri",
        :transfer_pet => "Transfer Pet",
        :blood_draw => "Blood Draw",
        :np_testing => "Np Testing",
        :lumbar_punture => "Lumbar Punture"
      )
    ])
  end

  it "renders a list of vgroups" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Note".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Transfer Mri".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Transfer Pet".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Blood Draw".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Np Testing".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Lumbar Punture".to_s, :count => 2
  end
end
