module LessonHelper

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
