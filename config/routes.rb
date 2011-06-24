Solar::Application.routes.draw do |map|

  resources :discussions
  resources :messages
  
  get "pages/index"

  get "access_control/index"
  get "users/mysolar"
  get "user_sessions/new"
  get "users/new"
  get "users/pwd_recovery"
  get "offers/showoffersbyuser"

  #################################
  # rotas regulares - Nao RESTful #
  #################################

  # roteamento para controle de acesso as imagens do usuario
  map.connect '/media/users/:id/photos/:style.:extension', :controller => 'access_control', :action => 'photo'

  # roteamento para controle de acesso as midias de aula
  map.connect '/media/lessons/:id/:file.:extension', :controller => 'access_control', :action => 'lesson'

  # roteamento para controle de acesso as midias de mensagem
  map.connect '/media/messages/:id/:file.:extension', :controller => 'access_control', :action => 'message'

  # redireciona para mysolar se o usuario estiver tentando acessar os dados de outros usuarios
  map.connect '/users/:id', :controller => 'users', :action => 'mysolar', :conditions => {:method => :get}
 
  # Definindo resources (mapeamento de urls para os objetos)

  resources :users, :user_sessions, :curriculum_units, :participants, :allocations, :portfolio
  
  match 'login' => "user_sessions#new", :as => :login
  match 'logout' => "user_sessions#destroy", :as => :logout

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  match ':controller(/:action(/:id(.:format)))'

  #root :to => 'user_sessions#new'
  root :to => 'pages#index'
    
end
