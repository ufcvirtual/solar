Solar::Application.routes.draw do 

  devise_for :users, :path_names => {:sign_up => :register}

  devise_scope :user do
    get "login", :to => "devise/sessions#new"
    get "logout", :to => "devise/sessions#destroy"
    get "/", :to => "devise/sessions#new"
    resources :sessions, :only => [:create]
  end

  ## curriculum_units/:id/groups
  #  O ":only" fica enquanto edição de UC não for finalizada
  resources :curriculum_units, :only => [:show] do
    get :participants, :on => :member
    get :informations, :on => :member
    get :home, :on => :member
    resources :groups, :only => [:index]
  end

  ## groups/:id/discussions
  resources :groups, :only => [] do
    resources :discussions, :only => [:index]
  end

  ## discussions/:id/posts
  resources :discussions, :only => [] do
    resources :posts, :except => [:show, :new, :edit]
    controller :posts do
      get "posts/user/:user_id", :to => :show, :as => "posts_of_the_user"
      get "posts/:type/:date(/order/:order(/limit/:limit))", :to => :index, :defaults => {:display_mode => 'list'} # :types => [:news, :history]; :order => [:asc, :desc]
    end
  end

  ## posts/:id/post_files
  resources :posts, :only => [] do
    resources :post_files, :only => [:new, :create, :destroy, :download] do
      get :download, :on => :member
    end
  end

  ## users/:id/photo
  ## users/edit_photo
  resources :users do
    get :photo, :on => :member
    get :edit_photo, :on => :collection
  end

  ## allocations/enrollments
  resources :allocations, :except => [:new] do
    get :enrollments, :action => :index, :on => :collection
    delete :cancel, :action => :destroy, :on => :member
    delete :cancel_request, :action => :destroy, :on => :member, :defaults => {:type => 'request'}
  end

  resources :scores, :only => [:show]
  resources :allocations, :courses, :group_assignments

  get "pages/index"
  get "pages/team"
  get "access_control/index"
  get "offers/showoffersbyuser"
  get "schedules/show"
  get "portfolio/public_files_send"
  get "scores/:id/history_access" => "scores#history_access"
  get 'home' => "users#mysolar", :as => :home
  get 'user_root' => 'users#mysolar'

  get "/media/users/:id/photos/:style.:extension", :to => "users#photo"
  get "/media/portfolio/individual_area/:file.:extension", :to => "access_control#portfolio_individual_area"
  get "/media/portfolio/public_area/:file.:extension", :to => "access_control#portfolio_public_area"
  get "/media/lessons/:id/:file.:extension", :to => "access_control#lesson"
  get "/media/messages/:file.:extension", :to => "access_control#message"

  match ':controller(/:action(/:id(.:format)))'

  root :to => 'devise/sessions#new'
end
