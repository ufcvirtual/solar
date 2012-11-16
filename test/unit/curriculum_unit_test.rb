require 'test_helper'

class  CurriculumUnitTest < ActiveSupport::TestCase

  fixtures :curriculum_units, :curriculum_unit_types

  test "codigo deve ser unico" do
  	curriculum_unit = CurriculumUnit.create(:code => curriculum_units(:r1).code, :name => "Curso 10", :curriculum_unit_type => curriculum_unit_types(:extensao), 
  		:resume => "Curso 10", :syllabus => "Curso 10", :objectives => "Curso 10")

  	assert (not curriculum_unit.valid?)
  	assert_equal curriculum_unit.errors[:code].first, I18n.t(:taken, :scope => [:activerecord, :errors, :messages])
	end

	test "codigo deve ter, no maximo, 10 caracteres" do
  	curriculum_unit = CurriculumUnit.create(:code => "C0000000010", :name => "Curso 10", :curriculum_unit_type => curriculum_unit_types(:extensao), :resume => "Curso 10", 
  		:syllabus => "Curso 10", :objectives => "Curso 10")

  	assert (not curriculum_unit.valid?)
  	assert_equal curriculum_unit.errors[:code].first, I18n.t(:too_long, :scope => [:activerecord, :errors, :messages], :count => 10)
	end

	test "nome deve ser preenchido" do
  	curriculum_unit = CurriculumUnit.create(:code => "C010", :curriculum_unit_type => curriculum_unit_types(:extensao), :resume => "Curso 10", :syllabus => "Curso 10", 
  		:objectives => "Curso 10")

  	assert (not curriculum_unit.valid?)
  	assert_equal curriculum_unit.errors[:name].first, I18n.t(:empty, :scope => [:activerecord, :errors, :messages])
	end

	test "nome deve ter, no maximo, 120 caracteres" do
  	curriculum_unit = CurriculumUnit.create(:code => "C010", :name => "Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  
  		Curso 10  Curso 10  ", :curriculum_unit_type => curriculum_unit_types(:extensao), :resume => "Curso 10", :syllabus => "Curso 10", :objectives => "Curso 10")

  	assert (not curriculum_unit.valid?)
  	assert_equal curriculum_unit.errors[:name].first, I18n.t(:too_long, :scope => [:activerecord, :errors, :messages], :count => 120)
	end

	test "tipo de unidade curricular deve ser selecionado" do
  	curriculum_unit1 = CurriculumUnit.create(:code => "C010", :name => "Curso 10", :resume => "Curso 10", :syllabus => "Curso 10", :objectives => "Curso 10", :passing_grade => 7)
  	curriculum_unit2 = CurriculumUnit.create(:code => "C010", :curriculum_unit_type_id => (CurriculumUnitType.all.last.id+1), :name => "Curso 10", :resume => "Curso 10", :syllabus => "Curso 10", :objectives => "Curso 10", :passing_grade => 7)

  	assert ((not curriculum_unit1.valid?) and (not curriculum_unit2.valid?))
  	assert_equal curriculum_unit1.errors[:curriculum_unit_type].first, I18n.t(:empty, :scope => [:activerecord, :errors, :messages])
  	assert_equal curriculum_unit2.errors[:curriculum_unit_type].first, I18n.t(:empty, :scope => [:activerecord, :errors, :messages])
	end

	test "resumo deve ser preenchido" do
  	curriculum_unit = CurriculumUnit.create(:code => "C010", :name => "Curso 10", :curriculum_unit_type => curriculum_unit_types(:extensao), :syllabus => "Curso 10", 
  		:objectives => "Curso 10")

  	assert (not curriculum_unit.valid?)
  	assert_equal curriculum_unit.errors[:resume].first, I18n.t(:empty, :scope => [:activerecord, :errors, :messages])
	end	

	test "ementa deve ser preenchida" do
  	curriculum_unit = CurriculumUnit.create(:code => "C010", :name => "Curso 10", :curriculum_unit_type => curriculum_unit_types(:extensao), :resume => "Curso 10", 
  		:objectives => "Curso 10")

  	assert (not curriculum_unit.valid?)
  	assert_equal curriculum_unit.errors[:syllabus].first, I18n.t(:empty, :scope => [:activerecord, :errors, :messages])  	
	end	

	test "objetivo deve ser preenchido" do
  	curriculum_unit = CurriculumUnit.create(:code => "C010", :name => "Curso 10", :curriculum_unit_type => curriculum_unit_types(:extensao), :resume => "Curso 10", 
  		:syllabus => "Curso 10")

  	assert (not curriculum_unit.valid?)
  	assert_equal curriculum_unit.errors[:objectives].first, I18n.t(:empty, :scope => [:activerecord, :errors, :messages])  	
	end	

	test "objetivo deve ter, no maximo, 255 caracteres" do
  	curriculum_unit = CurriculumUnit.create(:code => "C010", :name => "Curso 10", :curriculum_unit_type => curriculum_unit_types(:extensao), :resume => "Curso 10", 
  		:syllabus => "Curso 10", :objectives => "Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  
  		Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  Curso 10  ")

  	assert (not curriculum_unit.valid?)
  	assert_equal curriculum_unit.errors[:objectives].first, I18n.t(:too_long, :scope => [:activerecord, :errors, :messages], :count => 255)	
	end	

	test "media deve ser maior ou igual a 0 e menor ou igual a 10" do
  	curriculum_unit1 = CurriculumUnit.create(:code => "C010", :name => "Curso 10", :curriculum_unit_type => curriculum_unit_types(:extensao), :resume => "Curso 10", 
  		:syllabus => "Curso 10", :objectives => "Curso 10", :passing_grade => -3)
  	curriculum_unit2 = CurriculumUnit.create(:code => "C010", :name => "Curso 10", :curriculum_unit_type => curriculum_unit_types(:extensao), :resume => "Curso 10", 
  		:syllabus => "Curso 10", :objectives => "Curso 10", :passing_grade => 15)

		assert ((not curriculum_unit1.valid?) and (not curriculum_unit2.valid?))
  	assert_equal curriculum_unit1.errors[:passing_grade].first, I18n.t(:greater_than_or_equal_to, :scope => [:activerecord, :errors, :messages], :count => 0)	
  	assert_equal curriculum_unit2.errors[:passing_grade].first, I18n.t(:less_than_or_equal_to, :scope => [:activerecord, :errors, :messages], :count => 10)	
	end	

	test "media deve ser um numero" do
		curriculum_unit = CurriculumUnit.create(:code => "C010", :name => "Curso 10", :curriculum_unit_type => curriculum_unit_types(:extensao), :resume => "Curso 10", 
  		:syllabus => "Curso 10", :objectives => "Curso 10", :passing_grade => "Curso 10")

		assert (not curriculum_unit.valid?)
  	assert_equal curriculum_unit.errors[:passing_grade].first, I18n.t(:not_a_number, :scope => [:activerecord, :errors, :messages])	  	
	end	

end