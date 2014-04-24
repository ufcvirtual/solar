module OffersHelper

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

  ##
  # Retorna o nome da uc e curso
  ##
  def get_uc_and_course_names(allocation_tags_ids)
    # Como os valores que vêm das alocations são de ofertas, é necessário pegar apenas aquelas com uc e curso diferentes
    allocation_tags_ids = allocation_tags_ids.uniq {|a| 
      (AllocationTag.find(a).offer.course_id and AllocationTag.find(a).offer.curriculum_unit_id)
    }

    offers = Offer.joins(:allocation_tag).where(allocation_tags: {id: allocation_tags_ids})
    courses = offers.map(&:course).map(&:name).uniq
    ucs = offers.map(&:curriculum_unit).map(&:name).uniq

    return {"uc" => ucs.join(", "), "course" => courses.join(", ")}
  end

  def enrollment_info(offer)
    enrollment_period = offer.enrollment_period

    enrollment_dates = [I18n.l(enrollment_period.first, format: :normal), (enrollment_period.last.nil? ? I18n.t(:no_end_date, scope: :offers) : I18n.l(enrollment_period.last, format: :normal))].join(" - ")
    is_active = enrollment_period.first <= Time.now and (enrollment_period.last.nil? or enrollment_period.last >= Time.now)

    offer_period = [I18n.l(offer.start_date), (offer.end_date.nil? ? I18n.t(:no_end_date, scope: :offers) : I18n.l(offer.end_date))].join(" - ")
    {period: enrollment_dates, is_active: is_active, offer: offer_period}
  end

end
