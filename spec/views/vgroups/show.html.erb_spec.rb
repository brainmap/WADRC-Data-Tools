require 'spec_helper'

describe "vgroups/show.html.erb" do
  before(:each) do
    @vgroup = assign(:vgroup, stub_model(Vgroup,
      :participant_id => 1,
      :note => "Note",
      :transfer_mri => "Transfer Mri",
      :transfer_pet => "Transfer Pet",
      :blood_draw => "Blood Draw",
      :np_testing => "Np Testing",
      :lumbar_punture => "Lumbar Punture"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Note/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Transfer Mri/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Transfer Pet/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Blood Draw/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Np Testing/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Lumbar Punture/)
  end
end
