require 'spec_helper'

describe "lumbarpunctures/show.html.erb" do
  before(:each) do
    @lumbarpuncture = assign(:lumbarpuncture, stub_model(Lumbarpuncture,
      :appointment_id => 1,
      :completedlpfast => "Completedlpfast",
      :lp_examp_md_id => 1,
      :lpsucess => "Lpsucess",
      :lpabnormality => "Lpabnormality",
      :lpfollownote => "Lpfollownote"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Completedlpfast/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Lpsucess/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Lpabnormality/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Lpfollownote/)
  end
end
