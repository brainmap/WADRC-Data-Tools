require 'spec_helper'

describe "vgroups/new.html.erb" do
  before(:each) do
    assign(:vgroup, stub_model(Vgroup,
      :participant_id => 1,
      :note => "MyString",
      :transfer_mri => "MyString",
      :transfer_pet => "MyString",
      :blood_draw => "MyString",
      :np_testing => "MyString",
      :lumbar_punture => "MyString"
    ).as_new_record)
  end

  it "renders new vgroup form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => vgroups_path, :method => "post" do
      assert_select "input#vgroup_participant_id", :name => "vgroup[participant_id]"
      assert_select "input#vgroup_note", :name => "vgroup[note]"
      assert_select "input#vgroup_transfer_mri", :name => "vgroup[transfer_mri]"
      assert_select "input#vgroup_transfer_pet", :name => "vgroup[transfer_pet]"
      assert_select "input#vgroup_blood_draw", :name => "vgroup[blood_draw]"
      assert_select "input#vgroup_np_testing", :name => "vgroup[np_testing]"
      assert_select "input#vgroup_lumbar_punture", :name => "vgroup[lumbar_punture]"
    end
  end
end
