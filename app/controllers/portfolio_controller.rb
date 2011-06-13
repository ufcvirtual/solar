class PortfolioController < ApplicationController

  #  load_and_authorize_resource

  def list
    @curriculum_unit = CurriculumUnit.find(params[:id])

    group_id = session[:opened_tabs][session[:active_tab]]["groups_id"]
    #    offer_id = session[:opened_tabs][session[:active_tab]]["offers_id"]

    # atividades individuais
    # listando atividades individuais pelo grupo_id em que o usuario esta inserido
    @individual_activits = individual_activits(group_id, current_user.id)

    # area publica
    @public_area = public_area(group_id, current_user.id)

  end

  private

  # atividades individuais
  def individual_activits(group_id, user_id)

    query = "
    SELECT t1.name,
           t1.enunciation,
           t1.initial_date,
           t1.final_date,
           COALESCE(t2.grade::text, '-') AS grade,
           COUNT(t3.id) AS comments,
           CASE
            WHEN t2.grade IS NOT NULL THEN 'corrected'
            WHEN t2.id IS NOT NULL    THEN 'sent'
            WHEN t2.id IS NULL        THEN 'send'
           END AS correction
      FROM assignments         AS t1
      JOIN allocation_tags     AS t4 ON t4.id = t1.allocation_tag_id
      JOIN allocations         AS t5 ON t5.allocation_tag_id = t4.id
 LEFT JOIN send_assignments    AS t2 ON t2.assignment_id = t1.id
 LEFT JOIN assignment_comments AS t3 ON t3.send_assignment_id = t2.id
     WHERE t4.group_id = #{group_id}
       AND t5.user_id = #{user_id}
  GROUP BY t1.id, t2.id, t1.name, t1.enunciation, t1.initial_date, t1.final_date, t2.grade
  ORDER BY t1.final_date, t1.initial_date DESC;"

    ActiveRecord::Base.connection.select_all query

  end

  # arquivos da area publica
  def public_area(group_id, user_id)

    query = "
    SELECT t1.attachment_file_name,
           t1.attachment_content_type,
           t1.attachment_file_size
      FROM public_files AS t1
      JOIN allocation_tags AS t2 ON t2.id = t1.allocation_tag_id
      JOIN users AS t3 ON t3.id = t1.user_id
     WHERE t3.id = #{user_id}
       AND t2.group_id = #{group_id};"

    ActiveRecord::Base.connection.select_all query

  end

end
