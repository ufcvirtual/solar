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
	- Separar css da página
	- Configurar caminho para consultas ajax de Curso, unidade curricular, etc...
	- Colocar label indicando quais e quantas entidades estão selecionadas
	- colocar "alt" nas imagens
	- remover o '/assets' dos caminhos de imagens

=end

module PlacesNavPanelHelper

  def places_nav_panel_helper
    raw %{
	#{ javascript_include_tag "places_nav_panel"}
	#{ javascript_include_tag "jquery.tokeninput.js"}
	#{ javascript_include_tag "jquery.tokeninput.js"}
    #{ stylesheet_link_tag "places_nav_panel" }

	<div class="placesNavPanel">
		<div><span 
			class="label">[Gradua&ccedil;&atilde;o]:</span><input 
			type="text" id="txtCourse"/>
			<input type="button" value="" class ="btShowMenu"/>
		</div>
		<div><span 
			class="label">[Per&iacute;odo]:</span><input 
			type="text" id="txtSemester"/>
			<input type="button" value="" class ="btShowMenu"/>
		</div>
		<div><span 
			class="label">[Disciplina]:</span><input 
			type="text" id="txtCurriculumUnit"/>
			<input type="button" value="" class ="btShowMenu"/>
		</div>
		<div><span 
			class="label">[Turma]:</span><input 
			type="text" id="txtGroup"/>
			<input type="button" value="" class ="btShowMenu"/>
		</div>
		<div class="label summary">
			[qtd] [tipo] Selecionad[o/a(s)]
		</div>
	</div>

    }
  end

end
