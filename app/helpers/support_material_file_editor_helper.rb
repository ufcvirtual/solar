module SupportMaterialFileEditorHelper


    #################################
    ##### TRANSFERIR PARA VIEW ######
    # novo visual + Jquery ##########
    #################################


  def render_support_controll_tab
    	editor_tab  = String.new # string que armazena código para recriar abas de edição para o material de apoio do editor
      # combobox
      list_courses = Array.new # nome dos cursos
      courses_value_id = Array.new # id doscursos
      list_curriculum_unit = Array.new # nomes das disciplinas
      curriculum_unit_value_id = Array.new # id das disciplinas
      list_group_and_offer = Array.new
      offer_value_id = Array.new

      @select_options_editor.each do |d|
          list_courses << d['course']
          courses_value_id << d['course_id']

          list_curriculum_unit << d['name']
          curriculum_unit_value_id << d['curriculum_unit_id']

          list_group_and_offer << d['code'] + " " + d['semester']
          offer_value_id << d['id']
      end

    
    	editor_tab << "<div id='mysolar_tabs'>" # Estrutura de colunas da lista
    	editor_tab << " <ul  id='mysolar_tabs_wrapper'>"

      editor_tab << "   <li class=" # coluna do 'Documento'
      editor_tab << ((params[:support_document] == 'document') || (params[:support_document].nil?) ? "'mysolar_unit_active_tab'" : "'mysolar_unit_tab'")
      editor_tab << " id='editor_document'> #{link_to t(:support_send_document), :support_document => 'document', :value_id => params[:value_id], :type_value_id => params[:type_value_id], :curriculum_unit_id => params[:curriculum_unit_id], :offer_id => params[:offer_id]}</li>"

      editor_tab << "   <li class=" # coluna da 'Pasta'
      editor_tab << ((params[:support_document] == 'paste') ? "'mysolar_unit_active_tab'" : "'mysolar_unit_tab'")
      editor_tab << "id='editor_past'> #{link_to t(:support_create_paste), :support_document => 'paste', :value_id => params[:value_id], :type_value_id => params[:type_value_id], :curriculum_unit_id => params[:curriculum_unit_id], :offer_id => params[:offer_id]}</li>"

      editor_tab << "  <li class=" # coluna do 'Link'
      editor_tab << ((params[:support_document] == 'link') ? "'mysolar_unit_active_tab'" : "'mysolar_unit_tab'")
      editor_tab << "id='editor_link'> #{link_to t(:support_send_link), :support_document => 'link', :value_id => params[:value_id], :type_value_id => params[:type_value_id], :curriculum_unit_id => params[:curriculum_unit_id], :offer_id => params[:offer_id]}</li>"

      editor_tab << " </ul>"

      editor_tab << " <ul id='mysolar_extras'>"
      #editor_tab << "Curso: "
      #form_for(@editor_course_choose) do |f|
        #editor_tab << "#{f.select :course, options_for_select(Course.where(["id = ?", @editor_general_data["course_id"]]).collect{|c| [c.name]})}"
        #editor_tab << "#{f.select :course, options_for_select([["Dollar", "$"], ["Kroner", "DKK"]])}"
      #  editor_tab << "#{f.select :course, options_for_select([[""], [list_courses, courses_value_id]])}"
      #end


#
#    	editor_tab << "   Disciplina:"
#      form_for(@editor_curriculum_unit) do |f|
#        editor_tab << "#{f.select :curriculum, options_for_select([[list_curriculum_unit, curriculum_unit_value_id]])}"
#      end
#
#      editor_tab << "   Turma:"
#      form_for(@editor_group) do |f|
#        editor_tab << "#{f.select :group, options_for_select([[list_group_and_offer,offer_value_id]])}"
#      end
#      
      #editor_tab << "   Turma: "
    	#form_for(@offers) do |f|
      #   editor_tab << "#{f.select :group, options_for_select([""] + Group.find(:all,:select => "code").collect{|c| [c.code]})}"
      #end
      
      editor_tab << " </ul>"
    	editor_tab << "</div>"

	return editor_tab
  end

end
