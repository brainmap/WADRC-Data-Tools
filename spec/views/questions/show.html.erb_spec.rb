require 'spec_helper'

describe "questions/show.html.erb" do
  before(:each) do
    @question = assign(:question, stub_model(Question,
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
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Heading 1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Phrase A 1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Value Type 1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Ref Table A 1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Ref Table B 1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Phrase B 1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Phrase C 1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Required Y N 1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Heading 2/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Phrase A 2/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Value Type 2/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Ref Table A 2/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Ref Table B 2/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Phrase B 2/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Phrase C 2/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Required Y N 2/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Heading 3/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Phrase A 3/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Value Type 3/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Ref Table A 3/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Ref Table B 3/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Phrase B 3/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Phrase C 3/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Required Y N 3/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Status/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
