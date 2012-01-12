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
    	editor_tab << "Disciplina: "
      form_for(@editor_curriculun_unit) do |f|
        editor_tab << "#{f.select :offer, options_for_select([''] + CurriculumUnit.where(["curriculum_unit_type_id = ?", 3]).collect{|c| [c.name]})}"
      editor_tab << "</span>"
      end

      editor_tab << "   Turma: "
      editor_tab << "<span id='editor_groups'>"
      form_for(@editor_group) do |f|
        editor_tab << "#{f.select :offer, options_for_select([''] + Offer.find(:all,:select => 'semester').collect{|c| [c.semester]} + Group.find(:all,:select => "code").collect{|c| [c.code]})}"
      end
      editor_tab << "</span>"

      #editor_tab << "   Turma: "
    	#form_for(@offers) do |f|
      #   editor_tab << "#{f.select :group, options_for_select([""] + Group.find(:all,:select => "code").collect{|c| [c.code]})}"
      #end
      
      editor_tab << " </ul>"
    	editor_tab << "</div>"

	return editor_tab
  end

end
