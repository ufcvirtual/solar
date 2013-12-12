Solar::Application.routes.draw do 
  devise_for :users, path_names: {sign_up: :register}

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
      get "fb_feed/group/:id", to: "social_networks#fb_feed_groups", as: :fb_feed_group
    end
  end

  scope "/admin" do
    resources :profiles do
      get :permissions, on: :member
      post "permissions/grant", to: :grant, on: :member
    end
  end

  resources :administrations do
    member do
      put "update_allocation"
      put "update_user"
      put "update_profile"
      put "change_password"
    end
    collection do
      get :search_users
      get "user/:id/show_user", to: :show_user, as: :show_user
      get "user/:id/edit", to: :edit_user, as: :edit_user
      get "allocation/:id/show_allocation", to: :show_allocation, as: :show_allocation
      get "allocation/:id/edit", to: :edit_allocation, as: :edit_allocation
      get :allocations_user

      ## melhorar
      get :manage_user
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
        get :mobilis_list, to: :index, mobilis: true
      end
    end  
    get :list, on: :collection
    get :list_to_edit, to: :list, on: :collection, edition: true
    get :academic_index, on: :collection
  end

  ## discussions/:id/posts
  resources :discussions do
    collection do
      get :list
      put ":tool_id/unbind/group/:id" , to: "groups#change_tool", type: "unbind", tool_type: "Discussion", as: :unbind_group_from
      put ":tool_id/remove/group/:id" , to: "groups#change_tool", type: "remove", tool_type: "Discussion", as: :remove_group_from
      put ":tool_id/add/group/:id"    , to: "groups#change_tool", type: "add"   , tool_type: "Discussion", as: :add_group_to
    end
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
      get :student_view
      get :professor

      get :download_files
      get :send_public_files_page

      post :upload_file
      delete :delete_file

      put ":tool_id/unbind/group/:id" , to: "groups#change_tool", type: "unbind", tool_type: "Assignment", as: :unbind_group_from
      put ":tool_id/remove/group/:id" , to: "groups#change_tool", type: "remove", tool_type: "Assignment", as: :remove_group_from
      put ":tool_id/add/group/:id"    , to: "groups#change_tool", type: "add"   , tool_type: "Assignment", as: :add_group_to
    end
    member do
      get :information
      get :import_groups_page
      get :student
      post :evaluate
      post :send_comment
      post :manage_groups
      post :import_groups
      delete :remove_comment
    end
  end

  # chat
  resources :chat_rooms do
    collection do
      get :list
      put ":tool_id/unbind/group/:id" , to: "groups#change_tool", type: "unbind", tool_type: "ChatRoom", as: :unbind_group_from
      put ":tool_id/remove/group/:id" , to: "groups#change_tool", type: "remove", tool_type: "ChatRoom", as: :remove_group_from
      put ":tool_id/add/group/:id"    , to: "groups#change_tool", type: "add"   , tool_type: "ChatRoom", as: :add_group_to
    end
  end

  resources :agendas, only: [:index] do
    collection do
      get :list
      get :calendar
      get :events

      resources :assignment, only: [] do
        get "/:allocation_tags_ids", to: "agendas#dropdown_content", type: "Assignment", as: :dropdown_content_of, on: :member
      end
      resources :discussion, only: [] do
        get "/:allocation_tags_ids", to: "agendas#dropdown_content", type: "Discussion", as: :dropdown_content_of, on: :member
      end
      resources :chat_room, only: [] do
        get "/:allocation_tags_ids", to: "agendas#dropdown_content", type: "ChatRoom", as: :dropdown_content_of, on: :member
      end
      resources :schedule_event, only: [] do
        get "/:allocation_tags_ids", to: "agendas#dropdown_content", type: "ScheduleEvent", as: :dropdown_content_of, on: :member
      end
    end
  end

  resources :schedule_events, except: [:index]

  resources :messages, only: [:new, :show, :create, :index] do
    member do
      put ":box/:new_status", to: "messages#update", as: :change_status, constraints: {box: /(inbox)|(outbox)|(trashbox)/, new_status: /(read)|(unread)|(trash)|(restore)/}

      get :reply,     to: :reply, type: "reply"
      get :reply_all, to: :reply, type: "reply_all"
      get :forward,   to: :reply, type: "forward"
    end

    collection do
      put ":id", to: :create

      get :index,                    box: "inbox"
      get :inbox,    action: :index, box: "inbox",    as: :inbox
      get :outbox,   action: :index, box: "outbox",   as: :outbox
      get :trashbox, action: :index, box: "trashbox", as: :trashbox
      get :count_unread

      get "download/file/:file_id", to: "messages#download_files", as: :download_file
    end
  end

  resources :pages, only: [:index] do
    # get :team, on: :collection
  end

  resources :lesson_modules, except: [:index, :show] do
    collection do
      get :list
      put ":tool_id/unbind/group/:id" , to: "groups#change_tool", type: "unbind", tool_type: "LessonModule", as: :unbind_group_from
      put ":tool_id/remove/group/:id" , to: "groups#change_tool", type: "remove", tool_type: "LessonModule", as: :remove_group_from
      put ":tool_id/add/group/:id"    , to: "groups#change_tool", type: "add"   , tool_type: "LessonModule", as: :add_group_to
    end
  end

  # resources :tabs, only: [:show, :create, :destroy]
  get :activate_tab, to: "tabs#show", as: :activate_tab
  get :add_tab, to: "tabs#create", as: :add_tab
  get :close_tab, to: "tabs#destroy", as: :close_tab

  get :home, to: "users#mysolar", as: :home
  get :tutorials, to: "pages#tutorials", as: :tutorials
  get :user_root, to: 'users#mysolar'

  resources :support_material_files do
    get :download, on: :member
    collection do
      get :list
      get "at/:allocation_tag_id/download", to: :download, type: :all, as: :download_all
      get "at/:allocation_tag_id/folder/:folder/download", to: :download, type: :folder, as: :download_folder
      get "at/download", to: :download, type: :all, as: :download_all
      get "at/folder/:folder/download", to: :download, type: :folder, as: :download_folder
      put ":tool_id/unbind/group/:id" , to: "groups#change_tool", type: "unbind", tool_type: "SupportMaterialFile", as: :unbind_group_from
      put ":tool_id/remove/group/:id" , to: "groups#change_tool", type: "remove", tool_type: "SupportMaterialFile", as: :remove_group_from
      put ":tool_id/add/group/:id"    , to: "groups#change_tool", type: "add"   , tool_type: "SupportMaterialFile", as: :add_group_to
    end
  end

  resources :bibliographies, except: [:new, :show] do
    collection do
      get :list # edicao

      get :new_book           , to: :new, type_bibliography: Bibliography::TYPE_BOOK
      get :new_periodical     , to: :new, type_bibliography: Bibliography::TYPE_PERIODICAL
      get :new_article        , to: :new, type_bibliography: Bibliography::TYPE_ARTICLE
      get :new_electronic_doc , to: :new, type_bibliography: Bibliography::TYPE_ELECTRONIC_DOC
      get :new_free           , to: :new, type_bibliography: Bibliography::TYPE_FREE

      put ":tool_id/unbind/group/:id" , to: "groups#change_tool", type: "unbind", tool_type: "Bibliography", as: :unbind_group_from
      put ":tool_id/remove/group/:id" , to: "groups#change_tool", type: "remove", tool_type: "Bibliography", as: :remove_group_from
      put ":tool_id/add/group/:id"    , to: "groups#change_tool", type: "add"   , tool_type: "Bibliography", as: :add_group_to
    end
  end

  resources :notifications do
    collection do
      get :list # edicao

      put ":tool_id/unbind/group/:id" , to: "groups#change_tool", type: "unbind", tool_type: "Notification", as: :unbind_group_from
      put ":tool_id/remove/group/:id" , to: "groups#change_tool", type: "remove", tool_type: "Notification", as: :remove_group_from
      put ":tool_id/add/group/:id"    , to: "groups#change_tool", type: "add"   , tool_type: "Notification", as: :add_group_to
    end
  end

  get "/media/lessons/:id/:file.:extension", to: "access_control#lesson", index: true
  get "/media/lessons/:id/:folder/*path", to: "access_control#lesson", index: false

  get "/media/users/:user_id/photos/:style.:extension", to: "access_control#users"

  # get "/media/messages/:file.:extension", to: "access_control#message"
  get "/media/assignment/sent_assignment_files/:file.:extension", to: "access_control#assignment"
  get "/media/assignment/comments/:file.:extension", to: "access_control#assignment"
  get "/media/assignment/public_area/:file.:extension", to: "access_control#assignment"
  get "/media/assignment/enunciation/:file.:extension", to: "access_control#assignment"

  # IM
  # resources :instant_messages, only: [] do
  #   collection do
  #     get :prebind
  #   end
  # end

  root to: 'devise/sessions#new'
end
