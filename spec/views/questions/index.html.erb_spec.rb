require 'spec_helper'

describe "questions/index.html.erb" do
  before(:each) do
    assign(:questions, [
      stub_model(Question,
        :heading_1 => "Heading 1",
        :phrase_a_1 => "Phrase A 1",
        :value_type_1 => "Value Type 1",
        :ref_table_a_1 => "Ref Table A 1",
        :ref_table_b_1 => "Ref Table B 1",
        :phrase_b_1 => "Phrase B 1",
        :phrase_c_1 => "Phrase C 1",
        :required_y_n_1 => "Required Y N 1",
        :heading_2 => "Heading 2",
        :phrase_a_2 => "Phrase A 2",
        :value_type_2 => "Value Type 2",
        :ref_table_a_2 => "Ref Table A 2",
        :ref_table_b_2 => "Ref Table B 2",
        :phrase_b_2 => "Phrase B 2",
        :phrase_c_2 => "Phrase C 2",
        :required_y_n_2 => "Required Y N 2",
        :heading_3 => "Heading 3",
        :phrase_a_3 => "Phrase A 3",
        :value_type_3 => "Value Type 3",
        :ref_table_a_3 => "Ref Table A 3",
        :ref_table_b_3 => "Ref Table B 3",
        :phrase_b_3 => "Phrase B 3",
        :phrase_c_3 => "Phrase C 3",
        :required_y_n_3 => "Required Y N 3",
        :display_order => 1,
        :status => "Status",
        :parent_question_id => 1,
        :description => "Description"
      ),
      stub_model(Question,
        :heading_1 => "Heading 1",
        :phrase_a_1 => "Phrase A 1",
        :value_type_1 => "Value Type 1",
        :ref_table_a_1 => "Ref Table A 1",
        :ref_table_b_1 => "Ref Table B 1",
        :phrase_b_1 => "Phrase B 1",
        :phrase_c_1 => "Phrase C 1",
        :required_y_n_1 => "Required Y N 1",
        :heading_2 => "Heading 2",
        :phrase_a_2 => "Phrase A 2",
        :value_type_2 => "Value Type 2",
        :ref_table_a_2 => "Ref Table A 2",
        :ref_table_b_2 => "Ref Table B 2",
        :phrase_b_2 => "Phrase B 2",
        :phrase_c_2 => "Phrase C 2",
        :required_y_n_2 => "Required Y N 2",
        :heading_3 => "Heading 3",
        :phrase_a_3 => "Phrase A 3",
        :value_type_3 => "Value Type 3",
        :ref_table_a_3 => "Ref Table A 3",
        :ref_table_b_3 => "Ref Table B 3",
        :phrase_b_3 => "Phrase B 3",
        :phrase_c_3 => "Phrase C 3",
        :required_y_n_3 => "Required Y N 3",
        :display_order => 1,
        :status => "Status",
        :parent_question_id => 1,
        :description => "Description"
      )
    ])
  end

  it "renders a list of questions" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Heading 1".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Phrase A 1".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Value Type 1".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Ref Table A 1".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Ref Table B 1".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Phrase B 1".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Phrase C 1".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Required Y N 1".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Heading 2".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Phrase A 2".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Value Type 2".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Ref Table A 2".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Ref Table B 2".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Phrase B 2".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Phrase C 2".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Required Y N 2".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Heading 3".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Phrase A 3".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Value Type 3".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Ref Table A 3".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Ref Table B 3".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Phrase B 3".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Phrase C 3".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Required Y N 3".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Status".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
