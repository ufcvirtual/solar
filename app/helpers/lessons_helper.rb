module LessonsHelper

  def lessons_list(lessons, atual_id_open = nil)

    count, total_lesson = 1, lessons.length
    order_lesson, text = '', ''

    lessons.each do |l|
      order_lesson = (atual_id_open == l.lesson_id) ? count.to_s : order_lesson.to_s
       
     
      text_lesson = t(:lesson) + ' ' + count.to_s + ' - ' + total_lesson.to_s
       
       unless (l.schedule.end_date < Date.today || l.schedule.start_date > Date.today)
          text += "<span class='lesson_link' id='lesson_link#{count.to_s}' onclick=javascript:reload_frame('#{l.address}','#{URI.escape(text_lesson)}','#{count.to_s}')>"+count.to_s+"</span>"
       end
       
      count = count + 1
    end

    return text, order_lesson, total_lesson
  end

end
