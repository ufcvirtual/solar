class PortfolioController < ApplicationController

  #  load_and_authorize_resource

  def list
    @curriculum_unit = CurriculumUnit.find(params[:id])

    query = "
    SELECT t1.name,
           t1.enunciation,
           t1.initial_date,
           t1.final_date,
           COALESCE(t2.grade::text, '-') AS grade,
           COUNT(t3.id) AS comments
      FROM assignments         AS t1
      JOIN allocation_tags     AS t4 ON t4.id = t1.allocation_tag_id
 LEFT JOIN send_assignments    AS t2 ON t2.assignment_id = t1.id
 LEFT JOIN assignment_comments AS t3 ON t3.send_assignment_id = t2.id
     WHERE t4.id = #{params[:id]}
  GROUP BY t1.id, t2.id, t1.name, t1.enunciation, t1.initial_date, t1.final_date, t2.grade
  ORDER BY t1.final_date, t1.initial_date DESC;"

    @individual_activits = ActiveRecord::Base.connection.select_all query

  end

end
