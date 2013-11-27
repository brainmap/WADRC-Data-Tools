require 'spec_helper'

describe "cg_queries/show.html.erb" do
  before(:each) do
    @cg_query = assign(:cg_query, stub_model(CgQuery,
      :user_id => 1,
      :save_flag => "Save Flag",
      :encumber => "Encumber",
      :save_flag => "Save Flag",
      :rmr => "Rmr",
      :scan_procedure_id_list => "Scan Procedure Id List",
      :cg_name => "Cg Name",
      :gender => 1,
      :min_age => 1,
      :max_age => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Save Flag/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Encumber/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Save Flag/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Rmr/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Scan Procedure Id List/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Cg Name/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
  end
end
