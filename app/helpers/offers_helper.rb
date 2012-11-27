module OffersHelper

	##
  # Método que recupera as ofertas a serem listadas a partir dos valores de curso e uc selecionados no filtro (curriculum_unit_id e course_id)
  # curriculum_unit_id e course_id podem ser 0, "all" ou algum id específico.
  # 0, correspondente à seleção de "Nenhum" no filtro, não é aceito para a pesquisa de ofertas
  ##
  def get_offers(curriculum_unit_id, course_id)

    get_curriculum_units_and_courses(curriculum_unit_id, course_id) # retorna lista de cursos e ucs que usuário tem acesso

    # se algum valor for zero, a lista de ofertas será vazia
    unless course_id == 0 or curriculum_unit_id == 0
      all_offers      = []
      course          = Course.find(course_id) unless course_id == "all"
      curriculum_unit = CurriculumUnit.find(curriculum_unit_id) unless curriculum_unit_id == "all"

      if course_id == "all" # foram selecionados todos os cursos

        if curriculum_unit_id == "all" # e todas as uc
          all_offers << @curriculum_units.collect { |curriculum_unit| curriculum_unit.offers }
          all_offers << @courses.collect { |course| course.offers }
        else # e uma uc específico
          all_offers << curriculum_unit.offers
          all_offers << @courses.collect { |course| course.offers }
        end

      else # foi selecionado um curso específico

        if curriculum_unit_id == "all" # e todas as uc
          all_offers << course.offers
        else # e uma uc específica
          all_offers << @curriculum_units.collect { |curriculum_unit| curriculum_unit.offers }
        end

      end

      all_offers.flatten!
      all_offers.uniq! # deixa apenas as ofertas únicas
      
      # de todas as ofertas encontradas, recupera apenas aquelas que o usuário tem acesso
      @offers = all_offers.collect do |offer| 
        access_course          = Allocation.have_access?(current_user.id, offer.course.allocation_tag.id)
        access_curriculum_unit = Allocation.have_access?(current_user.id, offer.curriculum_unit.allocation_tag.id)
        access_offer           = Allocation.have_access?(current_user.id, offer.allocation_tag.id)

        # para adicionar a oferta à lista, o usuário deve ter acesso ao curso e à uc daquela oferta ou à própria oferta
        offer if (access_course and access_curriculum_unit) or access_offer
      end

      @offers.compact! # remove os valores nulos

    else

      @offers = []

    end

  end

  ##
  # Método que recupera uma lista com as ucs e uma lista com os cursos que o usuário tem acesso partindo dos valores selecionados por ele
  # Um parâmetro de valor 0 corresponde à seleção de "Nenhum" no filtro, o que não é aceito para a pesquisa de ofertas
  ##
  def get_curriculum_units_and_courses(curriculum_unit_id, course_id)

    @curriculum_units, @courses = [], []

    # se algum valor for zero, as listas serão vazias
    unless course_id == 0 or curriculum_unit_id == 0

      if course_id == "all" # todos os cursos
        # a não ser que o usuário não tenha acesso, adiciona o curso à lista
        @courses << Course.all.collect { |course| [course] if Allocation.have_access?(current_user.id, course.allocation_tag.id) } 
      else
        course = Course.find(course_id)
        # a não ser que o usuário não tenha acesso, adiciona o curso à lista
        @courses << [course] if Allocation.have_access?(current_user.id, course.allocation_tag.id)
      end

      @courses.flatten!
      @courses.compact!

      if curriculum_unit_id == "all"
        # a não ser que o usuário não tenha acesso, adiciona a uc à lista
        @curriculum_units << CurriculumUnit.all.collect { |curriculum_unit| [curriculum_unit] if Allocation.have_access?(current_user.id, curriculum_unit.allocation_tag.id)} 
      else
        curriculum_unit = CurriculumUnit.find(curriculum_unit_id)
        # a não ser que o usuário não tenha acesso, adiciona a uc à lista
        @curriculum_units << [curriculum_unit] if Allocation.have_access?(current_user.id, curriculum_unit.allocation_tag.id)
      end

      @curriculum_units.flatten!
      @curriculum_units.compact!

    end

  end

  ##
  # Retorna as allocations_tags_ids a partir das ofertas, uc ou curso passados
  ##
  def get_allocations_tags(offers, curriculum_unit_id, course_id)
    allocation_tags_ids = []
    allocation_tags_ids += [Course.find(course_id).allocation_tag.id]  unless course_id.nil? or course_id == "all"
    allocation_tags_ids += [CurriculumUnit.find(curriculum_unit_id).allocation_tag.id]  unless curriculum_unit_id.nil? or curriculum_unit_id == "all"
    allocation_tags_ids += offers.collect{ |offer| offer.allocation_tag.id } unless offers.nil?
    return allocation_tags_ids.uniq
  end


end