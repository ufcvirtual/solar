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

	<style>
		ul.token-input-list {
		    overflow: hidden; 
		    display:inline-block;
		    width: 450px;
		    border: 1px solid #8496ba;
		    cursor: text;
		    margin: 0;
		    padding: 0;
		    background-color: #fff;
		    height:28px;
		    line-height:28px;
		}

		ul.token-input-list li input {
		    border: 0;
		    width: 100px;
		    padding: 2px;
		    margin: 2px;
		    background-color: white;
		    -webkit-appearance: caret;
		}

		li.token-input-token {
		    overflow: hidden; 
		    height: auto !important; 
		    height: 15px;
		    margin: 3px;
		    padding: 1px 3px;
		    background-color: #eff2f7;
		    color: #000;
		    cursor: default;
		    border: 1px solid #ccd5e4;
		    font-size: 11px;
		    border-radius: 5px;
		    -moz-border-radius: 5px;
		    -webkit-border-radius: 5px;
		    float: left;
		    white-space: nowrap;
		    line-height:20px;
		}

		li.token-input-token p {
		    display: inline;
		    padding: 0;
		    margin: 0;
		}

		li.token-input-token span {
		    color: #a6b3cf;
		    margin-left: 5px;
		    font-weight: bold;
		    cursor: pointer;
		}

		li.token-input-selected-token {
		    background-color: #5670a6;
		    border: 1px solid #3b5998;
		    color: #fff;
		}

		li.token-input-input-token {
		    float: left;
		    margin: 0;
		    padding: 0;
		    list-style-type: none;
		}

		div.token-input-dropdown { 
   		    position: absolute;
		    width: 400px;
		    background-color: #fff;
		    overflow: hidden;
		    border-left: 1px solid #ccc;
		    border-right: 1px solid #ccc;
		    border-bottom: 1px solid #ccc;
		    cursor: default;
		    font-size: 11px;
		    font-family: Verdana;
		    z-index: 1;
		}

		div.token-input-dropdown p {
		    margin: 0;
		    padding: 5px;
		    font-weight: bold;
		    color: #777;
		}

		div.token-input-dropdown ul {
		    margin: 0;
		    padding: 0;
		}

		div.token-input-dropdown ul li {
		    background-color: #fff;
		    padding: 3px;
		    margin: 0;
		    list-style-type: none;
		}

		div.token-input-dropdown ul li.token-input-dropdown-item {
		    background-color: #fff;
		}

		div.token-input-dropdown ul li.token-input-dropdown-item2 {
		    background-color: #fff;
		}

		div.token-input-dropdown ul li em {
		    font-weight: bold;
		    font-style: normal;
		}

		div.token-input-dropdown ul li.token-input-selected-dropdown-item {
		    background-color: #3b5998;
		    color: #fff;
		}
	</style>
	<style>
		#navPanelMenu{
			position:absolute;
			top:0;
			left:0;
			margin: 4px;
			background-color:#bbb;
			margin: 0 0 0 3px;;
			padding: 5px 10px 0px 3px;
			list-style: none;
			display:block;
			z-index: 10;
			cursor:pointer;
			border: 2px solid #F9DB43;
			background-color: #fff;
			-webkit-box-shadow: 3px 3px 15px rgba(0, 0, 0, 0.23);
			-moz-box-shadow:    3px 3px 15px rgba(0, 0, 0, 0.23);
			box-shadow:         3px 3px 15px rgba(0, 0, 0, 0.23);
			-webkit-border-radius: 3px;
			-moz-border-radius: 3px;
			border-radius: 3px;
			font-size: 10pt;
		}
		#navPanelMenu li{
			white-space:nowrap;
			height: 1.6em;
			padding-right: 6px;
		}
		#navPanelMenu li a{
			color:#222;
			padding:0.2em
			text-decoration:none;
			display: inline-block;
			width:100%;
			padding: 0 10px 0 3px;
			margin-right: 10px;
			text-decoration:none;

			-webkit-transition: all 180ms linear;
			-moz-transition: all 180ms linear;
			-o-transition: all 180ms linear;
			-ms-transition: all 180ms linear;
			transition: all 180ms linear;
		}
		#navPanelMenu li a:hover{
			background-color: #f9ea9c;
			/*
			background: -webkit-linear-gradient(top, #016EE5 0%,#005CC0 100%);
			background: -o-linear-gradient(top, #016EE5 0%,#005CC0 100%);
			background: -ms-linear-gradient(top, #016EE5 0%,#005CC0 100%);
			background: linear-gradient(to bottom, #016EE5 0%,#005CC0 100%);
			filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#016ee5', endColorstr='#005cc0',GradientType=0 );
			*/
		}
		.placesNavPanel .btShowMenu{
			display:inline-block;
			line-height:28px;
			vertical-align:top;
			height:22px;
			width:22px;
 	   		line-height:22px;
 	   		background-image:url('/assets/gear.png');
 	   		background-repeat:no-repeat;
 	   		background-position:center;
 	   		background-color: #dedede;
 	   		border: 1px solid #D0D0D0;
 	   		margin-top:3px;

 	   	}
 	   	.placesNavPanel{
			background-color: transparent;
			line-height: 1.4em;
			margin-left:10px;
			width:600px;
		}
		.placesNavPanel>div{
			line-height:28px;
			padding:0px;
			margin:0px;
			vertical-align:middle;
			height:28px;
			margin-bottom:5px;
		}
		.placesNavPanel span.label{
			padding:0;
			margin:0;
			display:inline-block;
			width:100px;
			vertical-align:top;
		}
		.placesNavPanel .summary{
			font-size: 10pt;
			font-style: italic;
		}
		.placesNavPanel input[type="button"]{
			cursor:pointer;
			-webkit-border-radius: 2px;
			-moz-border-radius: 2px;
			border-radius: 2px;
		}
	</style>

    }
  end

end
