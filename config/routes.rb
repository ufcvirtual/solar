Solar::Application.routes.draw do 

  devise_for :users, :path_names => {:sign_in => "login", :sign_out => "logout", :sign_up => "register"}

  devise_scope :user do
    get "login", :to => "devise/sessions#new"
    get "logout", :to => "devise/sessions#destroy"
    get "/", :to => "devise/sessions#new"
  end

  get "pages/index"
  get "pages/team"
  get "access_control/index"
  get "offers/showoffersbyuser"
  get "schedules/show"
  get "portfolio/public_files_send"
  get "users/photo"


  # discussions/:id/posts
  resources :discussions, :only => [:show] do
    resources :posts, :except => [:show]
    controller :posts do
      # news
      match "posts/:date/news" => :list, :type => "news"
      match "posts/:date/news/:order/order" => :list, :type => "news"
      match "posts/:date/news/:limit/limit" => :list, :type => "news"
      match "posts/:date/news/:order/order/:limit/limit" => :list, :type => "news"
      # history
      match "posts/:date/history" => :list, :type => "history"
      match "posts/:date/history/:order/order" => :list, :type => "history"
      match "posts/:date/history/:limit/limit" => :list, :type => "history"
      match "posts/:date/history/:order/order/:limit/limit" => :list, :type => "history"
    end
  end

  #################################
  # rotas regulares - Nao RESTful #
  #################################

  # roteamento para controle de acesso a arquivos anexos a uma postagem
  match "/media/discussions/post/:file.:extension", :to => "access_control#discussion"

  # roteamento para controle de acesso a arquivos de atividades individuais/em grupo do portfolio de aluno (área individual)
  match "/media/portfolio/individual_area/:file.:extension", :to => "access_control#portfolio_individual_area"

  # roteamento para controle de acesso a arquivos de atividades individuais/em grupo do portfolio de aluno (área pública)
  match "/media/portfolio/public_area/:file.:extension", :to => "access_control#portfolio_public_area"

  # roteamento para controle de acesso as imagens do usuario
  match "/media/users/:id/photos/:style.:extension", :to => "access_control#photo"

  # roteamento para controle de acesso as midias de aula
  match "/media/lessons/:id/:file.:extension", :to => "access_control#lesson"

  # roteamento para controle de acesso as midias de mensagem
  match "/media/messages/:file.:extension", :to => "access_control#message"

  # redireciona para home se o usuario estiver tentando acessar os dados de outros usuarios
  match "/users/:id", :to => "users#mysolar", :via => "get"

  # Definindo resources (mapeamento de urls para os objetos)
  resources :users, :curriculum_units, :participants, :allocations, :courses, :scores

  match "scores/:id/history_access" => "scores#history_access"
  match 'home' => "users#mysolar", :as => :home

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  match ':controller(/:action(/:id(.:format)))'
  match 'user_root' => 'users#edit'

  #  root :to => "users#mysolar"
  root :to => 'devise/sessions#new'

end
