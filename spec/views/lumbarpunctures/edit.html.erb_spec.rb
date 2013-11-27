require 'spec_helper'

describe "lumbarpunctures/edit.html.erb" do
  before(:each) do
    @lumbarpuncture = assign(:lumbarpuncture, stub_model(Lumbarpuncture,
      :appointment_id => 1,
      :completedlpfast => "MyString",
      :lp_examp_md_id => 1,
      :lpsucess => "MyString",
      :lpabnormality => "MyString",
      :lpfollownote => "MyString"
    ))
  end

  it "renders the edit lumbarpuncture form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lumbarpuncture_path(@lumbarpuncture), :method => "post" do
      assert_select "input#lumbarpuncture_appointment_id", :name => "lumbarpuncture[appointment_id]"
      assert_select "input#lumbarpuncture_completedlpfast", :name => "lumbarpuncture[completedlpfast]"
      assert_select "input#lumbarpuncture_lp_examp_md_id", :name => "lumbarpuncture[lp_examp_md_id]"
      assert_select "input#lumbarpuncture_lpsucess", :name => "lumbarpuncture[lpsucess]"
      assert_select "input#lumbarpuncture_lpabnormality", :name => "lumbarpuncture[lpabnormality]"
      assert_select "input#lumbarpuncture_lpfollownote", :name => "lumbarpuncture[lpfollownote]"
    end
  end
end
