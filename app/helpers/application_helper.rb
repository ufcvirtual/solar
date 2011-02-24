module ApplicationHelper
  def categories
    categories = {t(:enrollm_pres_undergr_course) => Presential_Undergraduate_Course,
                  t(:enrollm_dist_undergr_course) => Distance_Undergraduate_Course,
                  t(:enrollm_free_course) => Free_Course,
                  t(:enrollm_ext_course) => Extension_Course,
                  t(:enrollm_pres_grad_course) => Presential_Graduate_Course,
                  t(:enrollm_dist_grad_course) => Distance_Graduate_Course
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
