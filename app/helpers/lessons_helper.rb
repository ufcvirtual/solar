module LessonsHelper

  def lessons_list(lessons, atual_id_open = nil)
    count, total_lesson = 1, lessons.length
    order_lesson, text = '', ''

    lessons.each do |l|
      order_lesson = (atual_id_open == l.lesson_id) ? count.to_s : order_lesson.to_s
      path_lesson = l.type_lesson == 1 ? l.address : "/media/lessons/#{l.allocation_tag_id}/#{l.address}"
      text_lesson = [t(:lesson, :scope => :lesson), ' ', count.to_s, ' - ', total_lesson.to_s].join('')

      unless (l.schedule.end_date.to_date < Date.today || l.schedule.start_date.to_date > Date.today)
        text << "<span class='lesson_link' id='lesson_link#{count.to_s}' onclick=javascript:reload_frame('#{path_lesson}','#{URI.escape(text_lesson)}','#{count.to_s}')>"+count.to_s+"</span>"
      end
       
      count = count + 1
    end

    return text, order_lesson, total_lesson
  end

end
