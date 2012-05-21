Solar::Application.routes.draw do 

  get "pages/index"
  get "pages/team"
  get "access_control/index"
  get "offers/showoffersbyuser"
  get "schedules/show"
  get "portfolio/public_files_send"
  get "users/photo"

  devise_for :users, :path_names => {:sign_up => :register}

  devise_scope :user do
    get "login", :to => "devise/sessions#new"
    get "logout", :to => "devise/sessions#destroy"
    get "/", :to => "devise/sessions#new"
    resources :sessions, :only => [:create]
  end

  # discussions/:id/posts
  resources :discussions, :only => [:index] do
    resources :posts, :except => [:show, :new, :edit]
    controller :posts do
      get "posts/:type/:date(/order/:order(/limit/:limit))" => 'posts#index' # types [:news, :history]; order [:asc, :desc]
    end
  end

  resources :posts, :only => [] do
    resources :post_files, :only => [:new, :create, :destroy, :download] do
      get :download, :on => :member
    end
  end

  resources :users, :curriculum_units, :participants, :allocations, :courses, :scores

  match "/media/users/:id/photos/:style.:extension", :to => "access_control#photo"
  match "/media/portfolio/individual_area/:file.:extension", :to => "access_control#portfolio_individual_area"
  match "/media/portfolio/public_area/:file.:extension", :to => "access_control#portfolio_public_area"
  match "/media/lessons/:id/:file.:extension", :to => "access_control#lesson"
  match "/media/messages/:file.:extension", :to => "access_control#message"

  match "scores/:id/history_access" => "scores#history_access"
  match 'home' => "users#mysolar", :as => :home
  match 'user_root' => 'users#mysolar'  

  match ':controller(/:action(/:id(.:format)))'

  root :to => 'devise/sessions#new'
end
