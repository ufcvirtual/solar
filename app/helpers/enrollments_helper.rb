module EnrollmentsHelper

  def to_combobox(options, select_id = 'cbx-enroll')
    result = "<select id=#{select_id}>"
    options.each { |label, value| result << %{<option value="#{value}">#{label}</option>} }
    result << "</select>"
  end

end
