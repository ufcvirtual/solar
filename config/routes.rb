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
    put :update_photo, on: :member
    get :edit_photo, on: :collection
    get :verify_cpf, on: :collection
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
      get :mobilis_list
      get :list_informations
      get :list_participants
      get :list_combobox, to: :index, combobox: true, as: :list_combobox
    end
    member do
      get :participants
      get :informations
      get :home
    end
    resources :groups, only: [:index] do
      collection do 
        get :mobilis_list
      end
    end
  end

  ## groups/:id/discussions
  resources :groups, except: [:show] do
    resources :discussions, only: [:index] do
      collection do 
        get :mobilis_list
      end
    end  
    get :list, on: :collection
    get :list_to_edit, to: :list, on: :collection, edition: true
    get :academic_index, on: :collection
    get :unbind, on: :member, to: :change_tool, type: "unbind"
    get :remove, on: :member, to: :change_tool, type: "remove"
    put :add, on: :collection, to: :change_tool, type: "add"
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
      put :deactivate
      put :activate
    end
  end

  resources :semesters, except: [:show] do
    get :list_combobox, to: :index, combobox: true, as: :list_combobox, on: :collection
    resources :offers, only: [:index, :new]
  end

  resources :offers, except: [:new] do
    post :deactivate_groups, on: :member
    get :list, on: :collection
  end

  resources :scores, only: [:index, :show] do
    collection do 
    get "student/:student_id", action: :show, as: :student
    get :amount_history_access
    get "history_access/:id", action: :history_access
    end
    get :history_access, on: :member
  end

  resources :enrollments, only: :index
  resources :courses do 
    get :list_combobox, to: :index, combobox: true, as: :list_combobox, on: :collection
  end

  resources :editions, only: [] do
    collection do
      get :items
      get :academic
      get :content
      get "academic/:curriculum_unit_type_id/courses", to: "editions#courses", as: :academic_courses
      get "academic/:curriculum_unit_type_id/curriculum_units", to: "editions#curriculum_units", as: :academic_uc
      get "academic/:curriculum_unit_type_id/semesters", to: "editions#semesters", as: :academic_semesters
      get "academic/:curriculum_unit_type_id/groups", to: "editions#groups", as: :academic_groups
    end
  end

  resources :lessons do
    member do
      put "change_status/:status", to: :change_status, as: :change_status
      get :header, to: :show_header
      get :content, to: :show_content
      put "order/:change_id", action: :order, as: :change_order
      put :change_module
    end
    collection do
      get :list, action: :list
      get :download_files
      get :verify_download
    end
    resources :files, controller: :lesson_files, except: [:index, :show, :update, :create] do
      collection do
        get "extract/:file", to: :extract_files, as: :extract, constraints: { file: /.*/ }
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

  resources :assignments do
    collection do
      get :student
      get :professor

      get :download_files
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

  resources :chat_rooms

  resources :schedules, only: [:index] do
    get :list, on: :collection
  end

  resources :messages, except: [:destroy, :update] do
    member do
      put ":box/:new_status", to: "messages#update", as: :change_status, constraints: {box: /(inbox)|(outbox)|(trashbox)/, new_status: /(read)|(unread)|(trash)|(restore)/}
    end

    collection do
      get :index, box: "inbox"
      get :inbox, action: :index, box: "inbox", as: :inbox
      get :outbox, action: :index, box: "outbox", as: :outbox
      get :trashbox, action: :index, box: "trashbox", as: :trashbox

      post :ajax_get_contacts
      post :send_message

      get "download/file/:file_id", to: "messages#download_files", as: :download_file
    end
  end

  resources :pages, only: [:index] do
    # get :team, on: :collection
  end

  resources :lesson_modules, except: [:index, :show]

  # resources :tabs, only: [:show, :create, :destroy]
  get :activate_tab, to: "tabs#show", as: :activate_tab
  get :add_tab, to: "tabs#create", as: :add_tab
  get :close_tab, to: "tabs#destroy", as: :close_tab

  get :home, to: "users#mysolar", as: :home
  get :user_root, to: 'users#mysolar'

  resources :support_material_files do
    get :download, on: :member
    collection do
      get :list
      get "at/:allocation_tag_id/download", to: :download, type: :all, as: :download_all
      get "at/:allocation_tag_id/folder/:folder/download", to: :download, type: :folder, as: :download_folder
      get "at/download", to: :download, type: :all, as: :download_all
      get "at/folder/:folder/download", to: :download, type: :folder, as: :download_folder
    end
  end

  get "bibliography/list", to: "bibliography#list"

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
