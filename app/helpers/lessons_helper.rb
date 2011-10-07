module LessonsHelper

  def return_lessons_to_open(offer_id = nil, group_id = nil, lesson_id = nil)

    # uma aula eh ligada a uma turma ou a uma oferta

    query_lessons = "SELECT distinct l.id as lessonid,
                            l.name, address,
                            l.order,l.schedule_id
                       FROM lessons l
                  LEFT JOIN schedules s ON l.schedule_id = s.id
                  LEFT JOIN allocation_tags at ON l.allocation_tag_id = at.id
                      WHERE status = #{Lesson_Approved}
                        AND s.start_date <= current_date
                       /* AND s.end_date >= current_date */ "
    unless (offer_id.nil? && group_id.nil?)
      query_lessons << " and ( "


      temp_query_lessons = []

      temp_query_lessons << " at.group_id in ( #{group_id} )" unless group_id.nil?
      temp_query_lessons << " at.offer_id in ( #{offer_id} )" unless offer_id.nil?
      temp_query_lessons << " at.group_id in ( select id from groups where offer_id=#{offer_id} ) "  unless offer_id.nil?

      query_lessons << temp_query_lessons.join(' OR ')
      
      query_lessons << "     ) "
    end
   
    #vê se passou lesson
    query_lessons += " and l.id=#{lesson_id} " unless lesson_id.nil? 

    query_lessons += " ORDER BY l.order"
puts "\n\n\n#{query_lessons}\n\n\n"
    return Lesson.find_by_sql(query_lessons)
  end

  def lesson_list (lessons)

    count=1
    total_lesson = lessons.length
    order_lesson = ''
    text = ''

    if !session[:opened_lesson].nil?
      atual_id = session[:opened_lesson].to_s
    end

    lessons.each do |l|
      order_lesson = (atual_id == l.lessonid) ? count.to_s : order_lesson.to_s

      text_lesson = t(:lesson) + ' ' + count.to_s + ' - ' + total_lesson.to_s
      text += "<span class='lesson_link' id='lesson_link#{count.to_s}' onclick=javascript:reload_frame('#{l.address}','#{URI.escape(text_lesson)}','#{count.to_s}')>"+count.to_s+"</span>"

      count=count+1
    end

    return text, order_lesson, total_lesson
  end

end
