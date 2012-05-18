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
  resources :discussions, :only => [:index] do
    resources :posts, :except => [:show, :new, :edit]
    controller :posts do
      # news
      match "posts/:date/news"                              => :index, :type => "news", :via => :get
      match "posts/:date/news/:order/order"                 => :index, :type => "news", :via => :get
      match "posts/:date/news/:limit/limit"                 => :index, :type => "news", :via => :get
      match "posts/:date/news/:order/order/:limit/limit"    => :index, :type => "news", :via => :get
      # history
      match "posts/:date/history"                           => :index, :type => "history", :via => :get
      match "posts/:date/history/:order/order"              => :index, :type => "history", :via => :get
      match "posts/:date/history/:limit/limit"              => :index, :type => "history", :via => :get
      match "posts/:date/history/:order/order/:limit/limit" => :index, :type => "history", :via => :get
    end
  end

  resources :posts, :only => [] do
    resources :post_files, :only => [:new, :create, :destroy, :download] do
      get :download, :on => :member
    end
  end

  match "/media/users/:id/photos/:style.:extension", :to => "access_control#photo"
  match "/media/portfolio/individual_area/:file.:extension", :to => "access_control#portfolio_individual_area"
  match "/media/portfolio/public_area/:file.:extension", :to => "access_control#portfolio_public_area"
  match "/media/lessons/:id/:file.:extension", :to => "access_control#lesson"
  match "/media/messages/:file.:extension", :to => "access_control#message"

  resources :users, :curriculum_units, :participants, :allocations, :courses, :scores

  match "scores/:id/history_access" => "scores#history_access"
  match 'home' => "users#mysolar", :as => :home

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  match ':controller(/:action(/:id(.:format)))'
  match 'user_root' => 'users#mysolar'

  root :to => 'devise/sessions#new'
end
