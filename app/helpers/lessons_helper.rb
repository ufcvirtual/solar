module LessonsHelper

  def return_lessons_to_open(offer_id = nil, group_id = nil, lesson_id = nil)

    # at.id as id, at.offer_id as offerid,l.allocation_tag_id as alloctagid,l.type_lesson, privacy,description,
    
    query_lessons = "select * from (SELECT distinct l.id as lessonid,
                           l.name, address, l.order, l.start, l.end
                      FROM lessons l
                      LEFT JOIN allocation_tags at ON l.allocation_tag_id = at.id
                    WHERE
                      status=#{Lesson_Approved} and l.start<=current_date and l.end>=current_date "

    #vê se passou offers
    if offer_id.nil? || offer_id==""
      query_lessons += " and at.offer_id in ( NULL )"
    else
      query_lessons += " and at.offer_id in ( #{offer_id} )"
    end

    #vê se passou lesson
    query_lessons += " and l.id=#{lesson_id} " unless lesson_id.nil? 

    query_lessons += " ORDER BY L.order) as query_offer

                    UNION ALL

                    select * from (SELECT distinct l.id as lessonid,
                           l.name, address, l.order, l.start, l.end
                      FROM lessons l
                      LEFT JOIN allocation_tags at ON l.allocation_tag_id = at.id
                    WHERE
                      status=#{Lesson_Approved} and l.start<=current_date and l.end>=current_date "

    #vê se passou groups
    if group_id.nil? || group_id==""
      query_lessons += " and at.group_id in ( NULL )"
    else
      query_lessons += " and at.group_id in ( #{group_id} )"
    end

    #vê se passou lesson
    query_lessons += " and l.id=#{lesson_id} " unless lesson_id.nil? 

    query_lessons += " ORDER BY L.order) as query_group"

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
