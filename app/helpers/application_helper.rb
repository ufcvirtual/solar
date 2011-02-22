module ApplicationHelper
  def categories
    categories = {"Disc. Grad. Presencial" => Presential_Undergraduate_Course,
                  "Disc. Grad. Semipresencial" => Distance_Undergraduate_Course,
                  "Curso Livre" => Free_Course,
                  "Curso de Extensao" => Extension_Course,
                  "Disc. Pos-Grad. Presencial" => Presential_Graduate_Course,
                  "Disc. Pos-Grad. Semipresencial" => Distance_Graduate_Course
    }
  end

  def message
		text = ""
		[:notice,:success,:error].each {|type|
			if flash[type]
				text += "<span class=\"#{type}\">#{flash[type]}</span>"
      end
		}
		text
	end
end
