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

  test "desabilitar alocacoes de um usuario em uma oferta" do
    user = users(:professor)
    offer = offers(:of3)

    assert offer.allocations.where(user_id: user, status: Allocation_Activated).count > 0

    offer.disable_user_allocations(user.id)

    assert offer.allocations.where(user_id: user, status: Allocation_Activated).count == 0
  end

  test "desabilitar alocacoes de um perfil de usuario em uma oferta" do
    user = users(:professor)
    offer = offers(:of3)
    profile = profiles(:prof_titular)

    assert offer.allocations.where(user_id: user, status: Allocation_Activated, profile_id: profile).count > 0

    offer.disable_user_profile_allocation(user.id, profile.id)

    assert offer.allocations.where(user_id: user, status: Allocation_Activated, profile_id: profile).count == 0
  end

  test "desabilitar alocacoes de usuario em uma oferta e relacionados" do
    user = users(:professor)
    offer = offers(:of3)

    group = offer.groups.create(code: "CODE01")
    profile = profiles(:prof_titular)
    group.allocate_user(user.id, profile.id)

    assert Allocation.where(allocation_tag_id: offer.allocation_tag.related(lower:true), status: Allocation_Activated, user_id: user.id).count > 1

    offer.disable_user_allocations_in_related(user.id)

    assert Allocation.where(allocation_tag_id: offer.allocation_tag.related(lower:true), status: Allocation_Activated, user_id: user.id).count == 0
  end

  test "desabilitar alocacoes de um perfil de usuario em uma oferta e relacionados" do
    user = users(:professor)
    offer = offers(:of3)
    group = offer.groups.create(code: "CODE02")

    profile = profiles(:aluno)
    group.allocate_user(user.id, profile.id)

    group = offer.groups.create(code: "CODE01")
    profile = profiles(:prof_titular)
    group.allocate_user(user.id, profile.id)
    
    assert Allocation.where(allocation_tag_id: offer.allocation_tag.related(lower:true), status: Allocation_Activated, user_id: user.id, profile_id: profile.id).count > 1
    assert Allocation.where(allocation_tag_id: offer.allocation_tag.related(lower:true), status: Allocation_Activated, user_id: user.id, profile_id: profile.id).count < Allocation.where(allocation_tag_id: offer.allocation_tag.related(lower:true), status: Allocation_Activated, user_id: user.id).count 

    offer.disable_user_profile_allocations_in_related(user.id, profile.id)

    assert Allocation.where(allocation_tag_id: offer.allocation_tag.related(lower:true), status: Allocation_Activated, user_id: user.id, profile_id: profile.id).count == 0
  end

  test "habilitar alocacoes de um usuario em uma oferta" do
    user = users(:professor)
    offer = offers(:of3)

    disabled_allocations_count = offer.allocations.where(user_id: user, status: Allocation_Cancelled).count
    enabled_allocations_count = offer.allocations.where(user_id: user, status: Allocation_Activated).count
    assert disabled_allocations_count > 0

    offer.enable_user_allocations(user.id)

    assert offer.allocations.where(user_id: user, status: Allocation_Activated).count == enabled_allocations_count + disabled_allocations_count
  end

  test "habilitar alocacoes de um perfil de usuario em uma oferta" do  
    user = users(:professor)
    offer = offers(:of3)
    profile = profiles(:tutor_distancia)
    
    disabled_allocations_count = offer.allocations.where(user_id: user, status: Allocation_Cancelled, profile_id: profile).count
    enabled_allocations_count = offer.allocations.where(user_id: user, status: Allocation_Activated, profile_id: profile).count
    assert disabled_allocations_count > 0

    offer.enable_user_profile_allocation(user.id, profile.id)

    assert offer.allocations.where(user_id: user, status: Allocation_Activated, profile_id: profile).count == enabled_allocations_count + disabled_allocations_count
  end

  test "habilitar alocacoes de usuario em uma oferta e relacionados" do
    user = users(:professor)
    offer = offers(:of3)

    disabled_allocations_count = Allocation.where(allocation_tag_id: offer.allocation_tag.related(lower:true), status: Allocation_Cancelled, user_id: user.id).count
    enabled_allocations_count = Allocation.where(allocation_tag_id: offer.allocation_tag.related(lower:true), status: Allocation_Activated, user_id: user.id).count
    assert disabled_allocations_count > 0
    
    offer.enable_user_allocations_in_related(user.id)

    assert Allocation.where(allocation_tag_id: offer.allocation_tag.related(lower:true), status: Allocation_Activated, user_id: user.id).count == enabled_allocations_count + disabled_allocations_count
  end

  test "habilitar alocacoes de um perfil de usuario em uma oferta e relacionados" do
    user = users(:professor)
    offer = offers(:of3)
    profile = profiles(:tutor_distancia)

    disabled_allocations_count = Allocation.where(allocation_tag_id: offer.allocation_tag.related(lower:true), status: Allocation_Cancelled, user_id: user.id, profile_id: profile.id ).count
    enabled_allocations_count  = Allocation.where(allocation_tag_id: offer.allocation_tag.related(lower:true), status: Allocation_Activated, user_id: user.id, profile_id: profile.id ).count
    assert disabled_allocations_count > 0

    offer.enable_user_profile_allocations_in_related(user.id, profile.id)

    assert Allocation.where(allocation_tag_id: offer.allocation_tag.related(lower:true), status: Allocation_Activated, user_id: user.id, profile_id: profile.id).count == enabled_allocations_count + disabled_allocations_count
  end
end
