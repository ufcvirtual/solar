class LessonController < ApplicationController
  #  load_and_authorize_resource
  before_filter :require_user, :only => [:list]

  def list
    # localiza unidade curricular
    @curriculum_unit = CurriculumUnit.find(params[:id])

    # pegando dados da sessao e nao da url
    offers_id = session[:opened_tabs][session[:active_tab]]["offers_id"]

    @lesson = nil

=begin
select * from (SELECT distinct at.id as id, at.offers_id as offerid, l.id as lessonid,
       l.allocation_tags_id as alloctagid,
       l.name, description, address, l.type, privacy, l.order, l.start, l.end
  FROM lessons l
  LEFT JOIN allocation_tags at ON l.allocation_tags_id = at.id
WHERE
	status=1 and l.start<=current_date and l.end>=current_date
	and (at.offers_id in ( 1 ))
ORDER BY L.order) as query_offer

union all

select * from (SELECT distinct at.id as id, at.offers_id as offerid, l.id as lessonid,
       l.allocation_tags_id as alloctagid,
       l.name, description, address, l.type, privacy, l.order, l.start, l.end
  FROM lessons l
  LEFT JOIN allocation_tags at ON l.allocation_tags_id = at.id
WHERE
	status=1 and l.start<=current_date and l.end>=current_date
	and (at.groups_id = 1)
ORDER BY L.order) as query_group
=end

  end
end
