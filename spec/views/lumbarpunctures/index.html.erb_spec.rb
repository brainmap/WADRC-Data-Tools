require 'spec_helper'

describe "lumbarpunctures/index.html.erb" do
  before(:each) do
    assign(:lumbarpunctures, [
      stub_model(Lumbarpuncture,
        :appointment_id => 1,
        :completedlpfast => "Completedlpfast",
        :lp_examp_md_id => 1,
        :lpsucess => "Lpsucess",
        :lpabnormality => "Lpabnormality",
        :lpfollownote => "Lpfollownote"
      ),
      stub_model(Lumbarpuncture,
        :appointment_id => 1,
        :completedlpfast => "Completedlpfast",
        :lp_examp_md_id => 1,
        :lpsucess => "Lpsucess",
        :lpabnormality => "Lpabnormality",
        :lpfollownote => "Lpfollownote"
      )
    ])
  end

  it "renders a list of lumbarpunctures" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Completedlpfast".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Lpsucess".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Lpabnormality".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Lpfollownote".to_s, :count => 2
  end
end
