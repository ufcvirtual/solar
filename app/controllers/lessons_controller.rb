class LessonsController < ApplicationController

  #  load_and_authorize_resource
  before_filter :require_user, :only => [:list, :show]

  def show
    render :layout => 'lesson'
  end

  def list
    if (params[:id])
      # localiza unidade curricular
      @curriculum_unit = CurriculumUnit.find(params[:id])
    else
      return
    end

    # recebe id da aula para exibicao
    @lesson = params[:lesson_id].nil? ? nil : Lesson.find(params[:lesson_id])

    # guarda em sessao id da aula aberta
    session[:opened_lesson] = @lesson.nil? ? nil : @lesson.id

    # pegando dados da sessao e nao da url
    groups_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    offers_id = session[:opened_tabs][session[:active_tab]]["offers_id"]

    query_lessons = "select * from (SELECT distinct at.id as id, at.offers_id as offerid, l.id as lessonid,
                           l.allocation_tags_id as alloctagid,
                           l.name, description, address, l.type_lesson, privacy, l.order, l.start, l.end
                      FROM lessons l
                      LEFT JOIN allocation_tags at ON l.allocation_tags_id = at.id
                    WHERE
                      status=#{Lesson_Approved} and l.start<=current_date and l.end>=current_date
                      and (at.offers_id in ( #{offers_id.nil? ? 'NULL' : offers_id} ))
                    ORDER BY L.order) as query_offer

                    UNION ALL

                    select * from (SELECT distinct at.id as id, at.offers_id as offerid, l.id as lessonid,
                           l.allocation_tags_id as alloctagid,
                           l.name, description, address, l.type_lesson, privacy, l.order, l.start, l.end
                      FROM lessons l
                      LEFT JOIN allocation_tags at ON l.allocation_tags_id = at.id
                    WHERE
                      status=#{Lesson_Approved} and l.start<=current_date and l.end>=current_date
                      and (at.groups_id in ( #{groups_id.nil? ? 'NULL' : groups_id} ))
                    ORDER BY L.order) as query_group"

    @lessons = Lesson.find_by_sql(query_lessons)

    # guarda lista de aulas para navegacao
    session[:lessons] = @lessons
  end

end
