require 'spec_helper'

describe "curriculum_units/show" do
  before(:each) do
    @curriculum_unit = assign(:curriculum_unit, stub_model(CurriculumUnit,
      :name => "Name",
      :code => "Code",
      :resume => "MyText",
      :syllabus => "MyText",
      :passing_grade => 1.5,
      :objectives => "Objectives",
      :prerequisites => ""
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(/Code/)
    rendered.should match(/MyText/)
    rendered.should match(/MyText/)
    rendered.should match(/1.5/)
    rendered.should match(/Objectives/)
    rendered.should match(//)
  end
end
