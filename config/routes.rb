Solar::Application.routes.draw do 

  devise_for :users, :path_names => {:sign_up => :register}

  devise_scope :user do
    get  :login, to: "devise/sessions#new"
    post :login, to: "devise/sessions#create"
    get  :logout, to: "devise/sessions#destroy"
    get "/", to: "devise/sessions#new"
    resources :sessions, only: [:create]
  end

  ## users/:id/photo
  ## users/edit_photo
  resources :users do
    get :photo, on: :member
    get :edit_photo, on: :collection
    put :update_photo, on: :member
  end

  resources :social_networks, only: [] do
    collection do
      get :fb_authenticate
      get :fb_feed
      get :fb_logout
      get :fb_post_wall
    end
  end

  ## curriculum_units/:id/participants
  ## curriculum_units/:id/informations
  resources :curriculum_units do
    collection do 
      get :list
      get :list_informations
      get :list_participants
    end
    member do
      get :participants
      get :informations
      get :home
    end
    resources :groups, only: [:index]
  end

  ## groups/:id/discussions
  resources :groups, except: [:show] do
    resources :discussions, only: [:index]
    get :list, on: :collection
  end

  ## discussions/:id/posts
  resources :discussions do
    get :list, on: :collection
    resources :posts, except: [:show, :new, :edit] do
      collection do
        get "user/:user_id", to: :show, as: :user
        get ":type/:date(/order/:order(/limit/:limit))", to: :index, defaults: {display_mode: 'list'} # :types => [:news, :history]; :order => [:asc, :desc]
      end
    end
  end

  ## posts/:id/post_files
  resources :posts, only: [:index] do
    resources :post_files, only: [:new, :create, :destroy, :download] do
      get :download, on: :member
    end
  end

  ## allocations/enrollments
  resources :allocations, except: [:new] do
    collection do
      get :designates
      get :enrollments, action: :index
      get :search_users
      post :create_designation
    end
    member do
      delete :cancel, action: :destroy
      delete :cancel_request, action: :destroy, defaults: {type: 'request'}
      post :reactivate
      post :deactivate
      post :activate
    end
  end
  
  resources :offers do
    post :deactivate_groups, on: :member
    get :list, on: :collection
  end

  resources :scores, only: [:index, :show] do
    get "student/:student_id", action: :show, on: :collection, as: :student
    get :history_access, on: :member
    get "amount_history_access/:id", action: :amount_history_access, on: :collection, as: :amount_history_access
    get "history_access/:id", action: :history_access, on: :collection
  end

  resources :enrollments, only: :index
  resources :courses

  resources :editions, only: [:index] do
    get :items, on: :collection
  end

  resources :lessons do
    member do
      put "change_status/:status", to: :change_status, as: :change_status
      get :header, to: :show_header
      get :content, to: :show_content
      get "extract_files/:file.:extension", action: :extract_files, as: :extract_file
      put "order/:change_id", action: :order, as: :change_order
    end
    collection do
      get :list, action: :list
      get :download_files
      get :verify_download
    end
    resources :files, controller: :lesson_files, except: [:index, :show, :update, :create] do
      collection do
        post :folder, to: :new, defaults: {type: 'folder'}, as: :new_folder
        post :file, to: :new, defaults: {type: 'file'}, as: :new_file
        put :rename_node, to: :edit, defaults: {type: 'rename'}
        put :move_nodes, to: :edit, defaults: {type: 'move'}
        put :upload_files, to: :new, defaults: {type: 'upload'}, as: :upload
        put :define_initial_file, to: :edit, defaults: {type: 'initial_file'}, as: :initial_file
        delete :remove_node, to: :destroy
      end
    end
  end
  get :lesson_files, to: "lesson_files#index", as: :lesson_files
 
  mount Ckeditor::Engine => "/ckeditor"

  resources :assignments, only: [:show] do
    collection do
      get :list
      get :download_files
      get :list_to_student
      get :send_public_files_page
      post :upload_file
      delete :delete_file
    end
    member do
      get :information
      get :import_groups_page
      post :evaluate
      post :send_comment
      post :manage_groups
      post :import_groups
      delete :remove_comment
    end
  end

  resources :schedules, only: [:index] do
    get :list, on: :collection
  end

  resources :messages do
    member do
      put :restore
      put :change_indicator_reading
    end
    collection do
      get :download_message_file
      post :ajax_get_contacts
      post :send_message
    end
  end

  resources :pages, only: [:index] do
    get :team, on: :collection
  end

  resources :lesson_modules, except: [:index, :show]

  # resources :tabs, only: [:show, :create, :destroy]
  get :activate_tab, to: "tabs#show", as: :activate_tab
  get :add_tab, to: "tabs#create", as: :add_tab
  get :close_tab, to: "tabs#destroy", as: :close_tab

  get :home, to: "users#mysolar", as: :home
  get :user_root, to: 'users#mysolar'

  get "support_material_files/list_edition", to: "support_material_files#list_edition"
  get "support_material_files/list", to: "support_material_files#list"
  get "support_material_files/download", to: "support_material_files#download"
  get "support_material_files/download_all_file_ziped", to: "support_material_files#download_all_file_ziped"
  get "support_material_files/download_folder_file_ziped", to: "support_material_files#download_folder_file_ziped"
  get "support_material_files/select_action_link", to: "support_material_files#select_action_link"
  get "support_material_files/select_action_file", to: "support_material_files#select_action_file"
  get "support_material_files/folder_verify", to: "support_material_files#folder_verify"
  get "support_material_files/delete_folder", to: "support_material_files#delete_folder"
  get "bibliography/list", to: "bibliography#list"

  ## aulas mapeando arquivos estaticos em aula
  get "/media/lessons/:id/:file.:extension", to: "access_control#lesson", index: true
  get "/media/lessons/:id/:folder/*path", to: "access_control#lesson", index: false

  get "/media/users/:user_id/photos/:style.:extension", to: "access_control#users"

  get "/media/messages/:file.:extension", to: "access_control#message"
  get "/media/assignment/sent_assignment_files/:file.:extension", to: "access_control#assignment"
  get "/media/assignment/comments/:file.:extension", to: "access_control#assignment"
  get "/media/assignment/public_area/:file.:extension", to: "access_control#assignment"
  get "/media/assignment/enunciation/:file.:extension", to: "access_control#assignment"

  root to: 'devise/sessions#new'

  # match ':controller(/:action(/:id(.:format)))'
end
