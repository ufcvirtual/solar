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

      #text += '<div id="lesson_click">'
      #text += "<a class='lesson_link' id='lesson_link#{count.to_s}' href=javascript:reload_frame('#{l.address}','#{URI.escape(text_lesson)}')>"+count.to_s+"</a>"
      #text += "</div>"

      text += "<span class='lesson_link' id='lesson_link#{count.to_s}' onclick=javascript:reload_frame('#{l.address}','#{URI.escape(text_lesson)}')>"+count.to_s+"</span>"

      count=count+1
    end

    return text, order_lesson, total_lesson
  end

=begin
totalAulas = count()

			if Session("safeQuerystring")("pos") <> "" then
			   pos = Session("safeQuerystring")("pos")
			else
			   pos = 1
			end if

			if totalAulas > 1 then

				'mostra link pra 10 aulas por vez
				primeira = pos - 4
				if primeira < 1 then primeira = 1
				ultima = primeira + 9
				if ultima > totalAulas then ultima = totalAulas

				if ultima - primeira < 9 then
					if (ultima - 10) < 1 then
						primeira = 1
					else
						primeira = ultima - 9
					end if
				end if

				for i = primeira to ultima
					if i = primeira then
						Response.Write "&nbsp;"
					end if

					Response.Write "<a "
					if cint(i) = cint(pos) Then
						Response.Write " class=aula "
					else
						Response.Write " class=bodyhead "
					End If
					Response.Write "href=" & chr(34) & "vis_aul_cab.asp" & CriptografaQueryString("t=" & TIPO_USER & "&c=" & ID_CURSO & "&pos=" & i) & chr(34) & " onmouseover=" & chr(34) & "window.status='';return true" & chr(34) & "> " & i & " </a>"

					if i < ultima then
						Response.Write "&nbsp;:&nbsp;"
					else
						Response.Write "&nbsp;"
					end if
				next
			end if
=end

end
