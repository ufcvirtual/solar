require 'spec_helper'

describe "curriculum_units/edit" do
  before(:each) do
    @curriculum_unit = assign(:curriculum_unit, stub_model(CurriculumUnit,
      :name => "MyString",
      :code => "MyString",
      :resume => "MyText",
      :syllabus => "MyText",
      :passing_grade => 1.5,
      :objectives => "MyString",
      :prerequisites => ""
    ))
  end

  it "renders the edit curriculum_unit form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => curriculum_units_path(@curriculum_unit), :method => "post" do
      assert_select "input#curriculum_unit_name", :name => "curriculum_unit[name]"
      assert_select "input#curriculum_unit_code", :name => "curriculum_unit[code]"
      assert_select "textarea#curriculum_unit_resume", :name => "curriculum_unit[resume]"
      assert_select "textarea#curriculum_unit_syllabus", :name => "curriculum_unit[syllabus]"
      assert_select "input#curriculum_unit_passing_grade", :name => "curriculum_unit[passing_grade]"
      assert_select "input#curriculum_unit_objectives", :name => "curriculum_unit[objectives]"
      assert_select "input#curriculum_unit_prerequisites", :name => "curriculum_unit[prerequisites]"
    end
  end
end
