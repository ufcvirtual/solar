# require 'spec_helper'

# describe "curriculum_units/index" do
#   before(:each) do
#     assign(:curriculum_units, [
#       stub_model(CurriculumUnit,
#         :name => "Name",
#         :code => "Code",
#         :resume => "MyText",
#         :syllabus => "MyText",
#         :passing_grade => 1.5,
#         :objectives => "Objectives",
#         :prerequisites => ""
#       ),
#       stub_model(CurriculumUnit,
#         :name => "Name",
#         :code => "Code",
#         :resume => "MyText",
#         :syllabus => "MyText",
#         :passing_grade => 1.5,
#         :objectives => "Objectives",
#         :prerequisites => ""
#       )
#     ])
#   end

#   it "renders a list of curriculum_units" do
#     render
#     # Run the generator again with the --webrat flag if you want to use webrat matchers
#     assert_select "tr>td", :text => "Name".to_s, :count => 2
#     assert_select "tr>td", :text => "Code".to_s, :count => 2
#     assert_select "tr>td", :text => "MyText".to_s, :count => 2
#     assert_select "tr>td", :text => "MyText".to_s, :count => 2
#     assert_select "tr>td", :text => 1.5.to_s, :count => 2
#     assert_select "tr>td", :text => "Objectives".to_s, :count => 2
#     assert_select "tr>td", :text => "".to_s, :count => 2
#   end
# end
