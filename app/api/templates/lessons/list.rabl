collection @lessons_modules

@lessons_modules.each do |lm|
  attributes :id, :name, :description, :order, :is_default

  child lm.lessons_to_open(current_user, list = true) => :lessons do |lessons|
    lessons.each do |l|
      attributes :id, :type_lesson, :name, :path, :order, :status

      glue l.schedule do
        attributes :start_date, :end_date
      end
    end
  end
end
