require 'test_helper'

class TaggableTest < ActiveSupport::TestCase

  fixtures :users, :courses, :curriculum_units, :groups, :offers

  # Método allocate_profiles
  test "cria alocacoes para cada perfil com permissao apos criacao" do
  	user_profiles_with_access = users(:editor).profiles.joins(:resources).where(resources: {action: 'create', controller: "curriculum_units"}).flatten

  	assert_difference("Allocation.count", +user_profiles_with_access.size) do # substituir por +(user_profiles_with_access.size*4) quando os demais ficarem prontos
  		CurriculumUnit.create(:code => "UC01", :name => "UC 01", :curriculum_unit_type => curriculum_unit_types(:extensao), :resume => "UC 01", 
  			:syllabus => "UC 01", :objectives => "UC 01", :user_id => users(:editor).id)

  		### # descomentar quando existirem nas resources/permissions_resources # ###

			# Offer.create(:course_id => courses(:c1).id, :curriculum_unit_id => curriculum_units(:r1).id, :semester => "2011.1", :start => "2011-03-10", 
  			# :end => "2021-12-01", :user_id => users(:editor).id) 

			# Group.create(:offer_id => offers(:of1).id, :code => "OF-OFERTA", :status => TRUE, :user_id => users(:editor).id) 

			# Course.create(:name => "Curso 10", :code => "C01", :user_id => users(:editor).id)
		end

  end


end
