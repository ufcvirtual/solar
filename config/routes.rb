Solar::Application.routes.draw do 

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

  # roteamento para controle de acesso a arquivos anexos a uma postagem
  match "/media/discussions/post/:file.:extension", :to => "access_control#discussion"

  # roteamento para controle de acesso as imagens do usuario
  match "/media/users/:id/photos/:style.:extension", :to => "access_control#photo"

  # roteamento para controle de acesso as midias de aula
  match "/media/lessons/:id/:file.:extension", :to => "access_control#lesson"

  # roteamento para controle de acesso as midias de mensagem
  match "/media/messages/:file.:extension", :to => "access_control#message"

  # redireciona para home se o usuario estiver tentando acessar os dados de outros usuarios
  match "/users/:id", :to => "users#mysolar", :via => "get"

  # Definindo resources (mapeamento de urls para os objetos)
  resources :users, :user_sessions, :curriculum_units, :participants, :allocations, :portfolio,:courses
  resources :scores

  match "scores/:id/history_access" => "scores#history_access"

  match 'login' => "user_sessions#new", :as => :login
  match 'logout' => "user_sessions#destroy", :as => :logout
  match 'home' => "users#mysolar", :as => :home

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  match ':controller(/:action(/:id(.:format)))'

  #root :to => 'user_sessions#new'
  root :to => 'pages#index'

end
