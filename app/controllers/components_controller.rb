class ComponentsController < ApplicationController

#Falta:
# Receber os Resources corretamente
# Receber o userId corretamente
# Separar css e script da view
# Colocar as chamadas AJAX para nao chamar endereços como http://localhost:3000/components/fill_curriculum_units'
# Checar se o componente se comporta adequadamente para usuários com perfil em turma, oferta e UC
# Será que é legal colocar um model soh para o componente?
# visual: Colocar Migalha de pão para exibição compacta
# visual: Dá pra indicar quando um item da lista é OK para o usuário? quando ele tem permissão para alterá-lo?
  
  #Preenche unidades curriculares do componente
  def fill_curriculum_units()
	#Recebendo lista de recursos sobre os quais o componente deve disponibilizar a navegação
	resources=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30]
	user_id = current_user.id
	user = User.find_by_id(user_id)
	#Recuperando lista de perfis com permissão de acessar o recurso que o componente trata.
	authorizes_profiles = Profile.authorized_profiles(resources)

	#Recupedando lista de unidades curriculares para as quais o usuário
	#possui um dos perfis encontrados, incluindo indiretamente 
	#(ex.: o perfil relacionado a uma oferta dessa unidade curricular.)
	@curricular_units = user.curriculumUnits_by_profile(authorizes_profiles)


	# nao renderiza o layout
    render :layout => false
  end

  def fill_offers()
	#Recebendo lista de recursos sobre os quais o componente deve disponibilizar a navegação
	resources=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30]
	user_id = current_user.id
	user = User.find_by_id(user_id)
	unit_id = params[:unit_id]

	#Recuperando lista de perfis com permissão de acessar o recurso que o componente trata.
	authorizes_profiles = Profile.authorized_profiles(resources)

	#Recupedando lista de ofertas para as quais o usuário
	#possui um dos perfis encontrados, incluindo indiretamente 
	@offers = user.offers_by_profile_and_curriculum_unit(authorizes_profiles, unit_id)

	# nao renderiza o layout
    render :layout => false
  end

  def fill_groups()
	#Recebendo lista de recursos sobre os quais o componente deve disponibilizar a navegação
	resources=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30]
	user_id = current_user.id
	user = User.find_by_id(user_id)
	offer_id = params[:offer_id]

	#Recuperando lista de perfis com permissão de acessar o recurso que o componente trata.
	authorizes_profiles = Profile.authorized_profiles(resources)

	#Recupedando lista de turmas para as quais o usuário
	#possui um dos perfis encontrados, incluindo indiretamente 
	@groups = user.groups_by_profile_and_offer(authorizes_profiles, offer_id)

	# nao renderiza o layout
    render :layout => false
  end

end
