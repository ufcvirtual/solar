module SupportMaterialFileEditorHelper

  def render_support_controll_tab
    	editor_tab  = String.new # string que armazena código para recriar abas de edição para o material de apoio do editor

    
    	editor_tab << "<div id='mysolar_tabs'>" # Estrutura de colunas da lista
    	editor_tab << " <ul  id='mysolar_tabs_wrapper'>"

      editor_tab << "   <li class=" # coluna do 'Documento'
      editor_tab << ((params[:support_document] == 'document') || (params[:support_document].nil?) ? "'mysolar_unit_active_tab'" : "'mysolar_unit_tab'")
      editor_tab << " id='editor_document'> #{link_to t(:support_send_document), :support_document => 'document' }</li>"

      editor_tab << "   <li class=" # coluna da 'Pasta'
      editor_tab << ((params[:support_document] == 'past') ? "'mysolar_unit_active_tab'" : "'mysolar_unit_tab'")
      editor_tab << "id='editor_past'> #{link_to t(:support_create_paste), :support_document => 'past'}</li>"

      editor_tab << "  <li class=" # coluna do 'Link'
      editor_tab << ((params[:support_document] == 'link') ? "'mysolar_unit_active_tab'" : "'mysolar_unit_tab'")
      editor_tab << "id='editor_link'> #{link_to t(:support_send_link), :support_document => 'link'}</li>"

      editor_tab << " </ul>"

      editor_tab << " <ul id='mysolar_extras'>"
      editor_tab << "Curso: "
      form_for(@editor_course_choose) do |f|
        list_courses = Course.where(["id = ?", @editor_general_data["course_id"]]).collect{|c| [c.name]}[0][0]
        courses_value_id = Course.where(["id = ?", @editor_general_data["course_id"]]).collect{|c| [c.id]}[0][0]
        #editor_tab << "#{f.select :course, options_for_select(Course.where(["id = ?", @editor_general_data["course_id"]]).collect{|c| [c.name]})}"
        #editor_tab << "#{f.select :course, options_for_select([["Dollar", "$"], ["Kroner", "DKK"]])}"
        editor_tab << "#{f.select :course, options_for_select([[list_courses, courses_value_id]])}"
      end



    	editor_tab << "   Disciplina:"
      form_for(@editor_curriculum_unit) do |f|
        list_curriculun_unit = CurriculumUnit.where(["curriculum_unit_type_id = ?", @editor_general_data["curriculum_unit_id"]]).collect{|c| [c.name]}[0][0]
        curriculun_unit_value_id = CurriculumUnit.where(["curriculum_unit_type_id = ?", @editor_general_data["curriculum_unit_id"]]).collect{|c| [c.id]}[0][0]
        editor_tab << "#{f.select :offer, options_for_select([[list_curriculun_unit, curriculun_unit_value_id]])}"
      end

      editor_tab << "   Turma:"
      form_for(@editor_group) do |f|
        list_group = Group.find(:all,:select => "code").collect{|c| [c.code]}[0][0]
        group_value_id = Group.find(:all,:select => "code").collect{|c| [c.id]}[0][0]
        editor_tab << "#{f.select :offer, options_for_select([[list_group,group_value_id]])}"
      end
      
      #editor_tab << "   Turma: "
    	#form_for(@offers) do |f|
      #   editor_tab << "#{f.select :group, options_for_select([""] + Group.find(:all,:select => "code").collect{|c| [c.code]})}"
      #end
      
      editor_tab << " </ul>"
    	editor_tab << "</div>"

	return editor_tab
  end

end
