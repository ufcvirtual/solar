=begin

  = Campos do filtro
    - Curso/Graduacao
    - Periodo/Oferta
    - Unidade Curricular
    - Turma

  = Listar apenas informações em que o usuário tem alguma ligação com permissão de edição
    - verificar em qual ponto da hierarquia o usuario tem permissao para visualizar
      - listar todas as informacoes abaixo desse ponto
        - uc, oferta, turma

  =====
  -- o usuario é obrigado a selecionar a allocation_tag onde tem associação (e as allocation_tags acima na hierarquia)
    -- se é associado a uma unidade curricular
      -- é obrigado a escolhar uma graduacao em um periodo, e o periodo
        -- esses campos nao podem ficar vazios ou com opcao --TODOSO--


  -- obrigar usuario a escolher uma opcao quando nem tem alocacao na hierarquia pra cima


TODO: 
	- Internacionalizar
	- Colocar label indicando quais e quantas entidades estão selecionadas
	- colocar "alt" nas imagens
	- remover o '/assets' dos caminhos de imagens
	- Pesquisa deve selecionar (Todos)
	- Preparar retorno (conjunto de allocationTags)
	- Colocar o Tab pra funcionar
    - Ver necessidade de indexar no BD os campos de busca para melhorar a performance de tudo.
=end

module PlacesNavPanelHelper

  def places_nav_panel_helper
    raw %{
	#{ javascript_include_tag "places_nav_panel"}
	#{ javascript_include_tag "jquery.tokeninput.js"}
    #{ stylesheet_link_tag "places_nav_panel" }

	<script type="text/javascript">

		//Declarando caminhos para a busca do componente. Nao conseguimos colocar isso no javascript		
		var search_urls = {
			"course": "#{url_for :controller => :courses, :format => "json"}", 
			"semester": "123", 
			"curriculumUnit": "#{url_for :controller => :curriculum_units, :format => "json"}",
			"group": "123"
		};
		
		var hints = {
			"course": "#{I18n.t(:places_nav_panel_course_hint)}", 
			"semester": "#{I18n.t(:places_nav_panel_semester_hint)}", 
			"curriculumUnit": "#{I18n.t(:places_nav_panel_curriculum_unit_hint)}",
			"group": "#{I18n.t(:places_nav_panel_group_hint)}"
		};
		
		var messages = {
			"searching": "#{I18n.t(:places_nav_panel_searching_text)}", 
			"noResults": "#{I18n.t(:places_nav_panel_empty_text)}"
		};
		
		
	</script>
	
	<div class="placesNavPanel">
		<div><span 
			class="label">#{t(:course)}:</span><input 
			type="text" id="txtCourse"/>
			<input type="button" value="" class ="btShowMenu"/>
		</div>
		<div><span 
			class="label">#{t(:semester_date)}:</span><input 
			type="text" id="txtSemester"/>
			<input type="button" value="" class ="btShowMenu"/>
		</div>
		<div><span 
			class="label" style=";">#{t(:curriculum_unit)}:</span><input 
			type="text" id="txtCurriculumUnit"/>
			<input type="button" value="" class ="btShowMenu"/>
		</div>
		<div><span 
			class="label">#{t(:group)}:</span><input 
			type="text" id="txtGroup"/>
			<input type="button" value="" class ="btShowMenu"/>
		</div>
		<div id="counterLabel" class="label summary">
			<span id="counter">0</span>
			<span id="counterDescription">[Turma(s) selecionada(s)]</span>
		</div>
	</div>

    }
  end

end
