Solar::Application.routes.draw do

  devise_for :users, controllers: { registrations: "devise/users", passwords: "devise/users_passwords" }

  authenticated :user do
    get "/", to: "users#mysolar"
  end

  devise_scope :user do
    get  :login, to: "devise/sessions#new"
    post :login, to: "devise/sessions#create"
    get  :logout, to: "devise/sessions#destroy"
    get "/", to: "devise/sessions#new"
    resources :sessions, only: [:create]
  end

  get :home, to: "users#mysolar", as: :home
  get :tutorials, to: "pages#tutorials", as: :tutorials
  get :apps, to: 'pages#apps', as: :apps
  get :privacy, to: 'pages#privacy', as: :privacy
  get :team, to: 'pages#team', as: :team
  get :faq, to: 'pages#faq', as: :faq
  get :tutorials_login, to: "pages#tutorials_login", as: :tutorials_login


  resources :users do
    member do
      get :photo
      put :update_photo
      get :reset_password_url
    end
    collection do
      get :edit_photo
      get :verify_cpf
      get :synchronize_ma
      get :profiles
      get :request_profile
    end
  end

  resources :personal_configurations do 
      put :update_theme, on: :collection
  end


  resources :social_networks, only: [] do
    collection do
      get :fb_authenticate
      get :fb_feed
      get :fb_logout
      get :fb_post_wall
      get "fb_feed/group/:id", to: "social_networks#fb_feed_groups", as: :fb_feed_group
      get "fb_feed/group/:id/news", to: "social_networks#fb_feed_group_news", as: :fb_feed_group_new
      get :fb_feed_new
    end
  end

  scope "/admin" do

    resources :blacklist, except: [:show, :edit, :update], controller: :user_blacklist do
      get :search, on: :collection
    end
    post "/blacklist/add_user/:user_id", to: "user_blacklist#add_user", as: :add_user_blacklist
    delete "/blacklist/remove_user/:user_cpf", to: "user_blacklist#destroy", type: 'remove', as: :remove_user_from_blacklist

    resources :profiles do
      get :permissions, on: :member
      put "permissions/grant", to: :grant, on: :member
    end

    get "allocations/:id", to: "administrations#show_allocation", as: :admin_allocation
    get "allocations/:id/edit", to: "administrations#edit_allocation", as: :edit_admin_allocation
    put "allocations/:id", to: "administrations#update_allocation"
    get "users/search", to: "administrations#search_users", as: :search_admin_users
    get "users/:id", to: "administrations#show_user", as: :admin_user
    put "users/:id", to: "administrations#update_user"
    put "users/:id/password", to: "administrations#reset_password_user", as: :reset_password_admin_user
    get "users/:id/edit", to: "administrations#edit_user", as: :edit_admin_user
    get "users/:id/allocations", to: "administrations#allocations_user", as: :allocations_admin_user
    get "users", to: "administrations#users", as: :admin_users

    get "responsibles/filter", to: "administrations#responsibles", as: :admin_responsibles_filter
    get "responsibles", to: "administrations#responsibles_list", as: :admin_responsibles

    ## logs
    get :logs, to: "administrations#logs", as: :logs
    get "logs/type/:type", to: "administrations#search_logs", as: :search_logs
    get "logs/type/navigation", to: "administrations#search_logs", as: :log_navigation

    ## import users
    get "/import/users/filter", to: "administrations#import_users", as: :import_users_filter
    get "/import/users/form", to: "administrations#import_users_form", as: :import_users_form
    post "/import/users/batch", to: "administrations#import_users_batch", as: :import_users_batch
    get "/import/users/log/:file", to: "administrations#import_users_log", as: :import_users_log
  end

  resources :administrations do
    collection do
      get :indication_users
      get :indication_users_specific
      get :indication_users_global
      get :allocation_approval
      get :search_allocation, action: :allocation_approval, defaults: {search: true}
      get :lessons
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

      get :participants
      get :informations
    end
    member do
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
    collection do
      get :list
      get :list_to_edit, to: :list, edition: true
      get :academic_index
      get :tags
    end
  end

  ## discussions/:id/posts
  resources :discussions do
    collection do
      get :list
      put ":tool_id/unbind/group/:id" , to: 'groups#change_tool', type: "unbind", tool_type: "Discussion", as: :unbind_group_from
      put ":tool_id/remove/group/:id" , to: 'groups#change_tool', type: "remove", tool_type: "Discussion", as: :remove_group_from
      put ":tool_id/add/group/:id"    , to: 'groups#change_tool', type: "add"   , tool_type: "Discussion", as: :add_group_to
      get ":tool_id/group/tags"       , to: 'groups#tags'                       , tool_type: "Discussion", as: :group_tags_from
    end
    put ':id/evaluate' , to: 'academic_allocation_users#evaluate', tool: 'Discussion', as: :evaluate, on: :member
    resources :posts, except: [:new, :edit] do
      collection do
        get "user/:user_id", to: :user_posts, as: :user
        get ":type/:date(/order/:order(/limit/:limit))", to: :index, defaults: {display_mode: 'list'} # :types => [:news, :history]; :order => [:asc, :desc]
      end
    end
  end

  ## posts/:id/post_files
  resources :posts, only: [:index] do
    member do
      get :to_evaluate , to: 'posts#index', as: :evaluate
    end
    resources :post_files, only: [:new, :create, :destroy, :download] do
      get :download, on: :member
      get :api_download, on: :member
    end
  end

  ## enroll_request: relacionado a pedido de matricula
  ## profile_request: relacionado a pedido de perfil
  resources :allocations, only: [:index, :show, :edit] do
    collection do

      ## menu
      get :manage_enrolls, to: redirect('/allocations/enrollments') #"allocations#index"
      get :enrollments, action: :index

      get :designates
      get :admin_designates, action: :designates, defaults: {admin: true}
      get :search_users

      post :create_designation # admin/editor add perfil

      post "profile/:profile_id", to: :profile_request, type: :profile, profile_request: true, as: :profile_request # pedir perfil
      post "enroll/:group_id", to: :enroll_request, type: :enroll, enroll_request: true, as: :enroll_request # pedir matricula
    end
    member do
      put :manage_enrolls

      delete :cancel, to: :update, type: :cancel, enroll_request: true
      delete :cancel_request, to: :update, type: :cancel_request, enroll_request: true
      delete :cancel_profile_request, action: :update, type: :cancel_profile_request, profile_request: true

      post :request_reactivate, to: :update, type: :request_reactivate, enroll_request: true
      put :deactivate, to: :update, type: :deactivate
      put :activate, to: :update, type: :activate

      put :reject, to: :update, type: :reject, acccept_or_reject_profile: true
      put :accept, to: :update, type: :accept, acccept_or_reject_profile: true
      put :undo_action, to: :update, type: :pending

      get :show_profile
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

  resources :scores, only: [:index] do
    collection do
      get :info
      get :search_tool
      get "user/:user_id/info", to: :user_info, as: :user_info
      get :amount_access
      get :evaluative, to: :evaluatives_frequency, type: 'evaluative'
      get :frequency, to: :evaluatives_frequency, type: 'frequency'
      get :not_evaluative, to: :evaluatives_frequency
      get :general
      get :redirect_to_evaluate
      get :reports_pdf
      get :redirect_to_open
    end
  end

  resources :edx_courses, only: [:index, :new] do
    collection do
      post :create, as: :create
      post "delete/:course", to: :delete, as: :delete
      get :my
      get :available
      post "enroll/:course", to: :enroll, as: :enroll
      post "unenroll/:course", to: :unenroll, as: :unenroll
      get :content
      get :search_users
      get :items
      get "designates/:course", to: :designates, as: :designates
      post "allocate/:username/:course/:profile", to: :allocate, as: :allocate
      post "deallocate/:username/:course/:profile", to: :deallocate, as: :deallocate
    end
  end

  resources :enrollments, only: :index do
    collection do
      get ":group_id", to: :show, as: :group
      get :public_course, action: :show, defaults: { public: true }
    end
  end

  resources :courses do
    get :list_combobox, to: :index, combobox: true, as: :list_combobox, on: :collection
  end

  resources :editions, only: [] do
    collection do
      get :items
      get :academic
      get :content
      get :repositories
      get :tool_management
      get :discussion_tool_management, tool_name: 'Discussion', to: :tool_management
      get :exam_tool_management, tool_name: 'Exam', to: :tool_management
      get :assignment_tool_management, tool_name: 'Assignment', to: :tool_management
      get :chat_tool_management, tool_name: 'ChatRoom', to: :tool_management
      get :webconference_tool_management, tool_name: 'Webconference', to: :tool_management
      put :manage_tools
      get "academic/:curriculum_unit_type_id/courses", to: "editions#courses", as: :academic_courses
      get "academic/:curriculum_unit_type_id/curriculum_units", to: "editions#curriculum_units", as: :academic_uc
      get "academic/:curriculum_unit_type_id/semesters", to: "editions#semesters", as: :academic_semesters
      get "academic/:curriculum_unit_type_id/groups", to: "editions#groups", as: :academic_groups
      get "academic/:curriculum_unit_type_id/edx_courses", to: "editions#edx_courses", as: :academic_edx_courses
    end
  end

  resources :lesson_modules, except: [:index, :show] do
    get :lessons, to: "lessons#to_filter"
    collection do
      get :list
      put ":tool_id/unbind/group/:id" , to: 'groups#change_tool', type: "unbind", tool_type: "LessonModule", as: :unbind_group_from
      put ":tool_id/remove/group/:id" , to: 'groups#change_tool', type: "remove", tool_type: "LessonModule", as: :remove_group_from
      put ":tool_id/add/group/:id"    , to: 'groups#change_tool', type: "add"   , tool_type: "LessonModule", as: :add_group_to
      get ":tool_id/group/tags"       , to: 'groups#tags'                       , tool_type: "LessonModule", as: :group_tags_from
    end
  end

  resources :lessons do
    member do
      put "change_status/:status", to: :change_status, as: :change_status
      put "responsible_change_status/:status", to: :change_status, as: :responsible_change_status, defaults: { responsible: true }
      put "order/:change_id", action: :order, as: :change_order
      put :change_module
      get :edition, action: :open, defaults: { edition: true }
      get :open
    end
    collection do
      get 'open_module/:lesson_module_id', action: :open_module, as: :open_module
      get :list, action: :list
      get :download_files
      get :verify_download

      ## import lessons
      get "/import/lessons/steps",   to: "lessons#import_steps",   as: :import_steps
      get "/import/lessons/list",    to: "lessons#import_list",    as: :import_list
      get "/import/lessons/details", to: "lessons#import_details", as: :import_details
      get "/import/lessons/preview", to: "lessons#import_preview", as: :import_preview
      put "/import/lessons/",        to: "lessons#import",         as: :import
    end
    resources :files, controller: :lesson_files, except: [:index, :show, :update, :create] do
      collection do
        get "extract/:file", to: :extract_files, as: :extract, constraints: { file: /.*/ }
        post :folder, to: :new, defaults: { type: 'folder' }, as: :new_folder
        post :file, to: :new, defaults: { type: 'file' }, as: :new_file
        put :rename_node, to: :edit, defaults: { type: 'rename' }
        put :move_nodes, to: :edit, defaults: { type: 'move' }
        put :upload_files, to: :new, defaults: { type: 'upload' }, as: :upload
        put :define_initial_file, to: :edit, defaults: { type: 'initial_file' }, as: :initial_file
        delete :remove_node, to: :destroy
      end
    end
    resources :notes, controller: :lesson_notes, only: [:index]
  end

  resources :lnotes, controller: :lesson_notes, except: [:index, :create, :update] do
    put :update, to: :create_or_update, on: :member
    collection do
      post :create, to: :create_or_update
      post :create_or_update
      get :download
      get :find
    end
  end

  get :lesson_files, to: "lesson_files#index", as: :lesson_files

  # Digital Class
  resources :digital_classes, except: :show do
    collection do
      get :list
      get :list_without_layout, to: :list, defaults: { layout: true }

      put ":tool_id/remove/group/:id" , to: 'digital_classes#change_tool', type: "remove", tool_type: "DigitalClass", as: :remove_group_from
      delete ":tool_id/remove/group/:id" , to: 'digital_classes#change_tool', type: "remove", tool_type: "DigitalClass", as: :remove_group_or_lesson
      put ":tool_id/add/group/:id"    , to: 'digital_classes#change_tool', type: "add"   , tool_type: "DigitalClass", as: :add_group_to
      get ":tool_id/group/tags"       , to: 'digital_classes#tags'                       , tool_type: "DigitalClass", as: :group_tags_from

      get :update_members_and_roles, to: :update_members_and_roles_page
      put :update_members_and_roles

      get :lesson, to: :new, lesson: true 
    end
    
    member do
      get :authenticate
      get :list_access 
      get :access
    end
  end

  resources :assignments do
    member do
      get :student
      get :participants
      put ':id/evaluate' , to: 'academic_allocation_users#evaluate', tool: 'Assignment', as: :evaluate
    end

    collection do
      get :list
      get :list_without_layout, to: :list, defaults: { layout: true }
      get :download
      get :zip_download, to: :download, defaults: { zip: true }

      put ":tool_id/unbind/group/:id" , to: 'groups#change_tool', type: "unbind", tool_type: "Assignment", as: :unbind_group_from
      put ":tool_id/remove/group/:id" , to: 'groups#change_tool', type: "remove", tool_type: "Assignment", as: :remove_group_from
      put ":tool_id/add/group/:id"    , to: 'groups#change_tool', type: "add"   , tool_type: "Assignment", as: :add_group_to
      get ":tool_id/group/tags"       , to: 'groups#tags'                       , tool_type: "Assignment", as: :group_tags_from
    end
  end

  resources :assignment_comments do
    get :download, on: :collection
  end

  resources :assignment_files do
    collection do
      get :download
      get :zip_download, to: :download, defaults: {zip: true}
    end
  end

  resources :public_files, except: [:edit, :update, :show] do
    collection do
      get :download
      get :zip_download, to: :download, defaults: {zip: true}
    end
  end

  resources :group_assignments, except: [:new] do
    collection do
      get :students_with_no_group
      get :import_list
      get :list
    end
    member do
      get :participants
      get :import_participants, to: :participants, defaults: {import: true}
      put :remove_participant, to: :change_participant
      put :add_participant, to: :change_participant, defaults: {add: true}
      post :import
    end

  end

  # chat
  resources :chat_rooms do
    collection do
      get :list
      put ":tool_id/unbind/group/:id" , to: 'groups#change_tool', type: "unbind", tool_type: "ChatRoom", as: :unbind_group_from
      put ":tool_id/remove/group/:id" , to: 'groups#change_tool', type: "remove", tool_type: "ChatRoom", as: :remove_group_from
      put ":tool_id/add/group/:id"    , to: 'groups#change_tool', type: "add"   , tool_type: "ChatRoom", as: :add_group_to
      get ":tool_id/group/tags"       , to: 'groups#tags'                       , tool_type: "ChatRoom", as: :group_tags_from
    end
    
    member do 
      get :user_messages
      put ':id/evaluate' , to: 'academic_allocation_users#evaluate', tool: 'ChatRoom', as: :evaluate
      get :messages
      get :access
      get :participants
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
      resources :lesson, only: [] do
        get "/:allocation_tags_ids", to: "agendas#dropdown_content", type: "Lesson", as: :dropdown_content_of, on: :member
      end
      resources :exam, only: [] do
        get "/:allocation_tags_ids", to: "agendas#dropdown_content", type: "Exam", as: :dropdown_content_of, on: :member
      end
    end
  end

  resources :schedule_events, except: [:index] do
    member do
      get :evaluate_user
      put ':id/evaluate' , to: 'academic_allocation_users#evaluate', tool: 'ScheduleEvent', as: :evaluate
    end
  end

  resources :messages, only: [:new, :show, :create, :index] do
    member do
      put ":box/:new_status", to: "messages#update", as: :change_status, constraints: { box: /(inbox)|(outbox)|(trashbox)/, new_status: /(read)|(unread)|(trash)|(restore)/ }

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
      get :find_users
      get :contacts
      get :search

      get "download/file/:file_id", to: "messages#download_files", as: :download_file

      get :support_new, to: "messages#new", as: :support_new, support: true
    end
  end

  # resources :tabs, only: [:show, :create, :destroy]
  get :activate_tab, to: "tabs#show"   , as: :activate_tab
  get :add_tab     , to: "tabs#create" , as: :add_tab
  get :close_tab   , to: "tabs#destroy", as: :close_tab

  resources :support_material_files do
    collection do
      get :list
      get "at/:allocation_tag_id/download", to: :download, type: :all, as: :download_all
      get "at/:allocation_tag_id/folder/:folder/download", to: :download, type: :folder, as: :download_folder
      get "at/download", to: :download, type: :all, as: :download_all
      get "at/folder/:folder/download", to: :download, type: :folder, as: :download_folder
      put ":tool_id/unbind/group/:id" , to: 'groups#change_tool', type: 'unbind', tool_type: 'SupportMaterialFile', as: :unbind_group_from
      put ":tool_id/remove/group/:id" , to: 'groups#change_tool', type: 'remove', tool_type: 'SupportMaterialFile', as: :remove_group_from
      put ":tool_id/add/group/:id"    , to: 'groups#change_tool', type: 'add'   , tool_type: 'SupportMaterialFile', as: :add_group_to
      get ":tool_id/group/tags"       , to: 'groups#tags'                       , tool_type: 'SupportMaterialFile', as: :group_tags_from
    end
    get :download, on: :member
  end

  resources :bibliographies, except: [:new, :show] do
    collection do
      get :list # edicao

      get :new_book           , to: :new, type_bibliography: Bibliography::TYPE_BOOK
      get :new_periodical     , to: :new, type_bibliography: Bibliography::TYPE_PERIODICAL
      get :new_article        , to: :new, type_bibliography: Bibliography::TYPE_ARTICLE
      get :new_electronic_doc , to: :new, type_bibliography: Bibliography::TYPE_ELECTRONIC_DOC
      get :new_free           , to: :new, type_bibliography: Bibliography::TYPE_FREE
      get :new_file           , to: :new, type_bibliography: Bibliography::TYPE_FILE

      put ':tool_id/unbind/group/:id' , to: 'groups#change_tool', type: 'unbind', tool_type: 'Bibliography', as: :unbind_group_from
      put ':tool_id/remove/group/:id' , to: 'groups#change_tool', type: 'remove', tool_type: 'Bibliography', as: :remove_group_from
      put ':tool_id/add/group/:id'    , to: 'groups#change_tool', type: 'add'   , tool_type: 'Bibliography', as: :add_group_to
      get ':tool_id/group/tags'       , to: 'groups#tags'                       , tool_type: 'Bibliography', as: :group_tags_from

      get :zip_download, to: :download, zip: true
    end

    get :download, on: :member, zip: false
  end

  resources :notifications do
    collection do
      get :list # edicao

      put ':tool_id/unbind/group/:id' , to: 'groups#change_tool', type: 'unbind', tool_type: 'Notification', as: :unbind_group_from
      put ':tool_id/remove/group/:id' , to: 'groups#change_tool', type: 'remove', tool_type: 'Notification', as: :remove_group_from
      put ':tool_id/add/group/:id'    , to: 'groups#change_tool', type: 'add'   , tool_type: 'Notification', as: :add_group_to
      get ':tool_id/group/tags'       , to: 'groups#tags'                       , tool_type: 'Notification', as: :group_tags_from
    end
  end

  resources :webconferences, except: :show do
    collection do
      get :list
      get :preview

      put ':tool_id/unbind/group/:id' , to: 'groups#change_tool', type: 'unbind', tool_type: 'Webconference', as: :unbind_group_from
      put ':tool_id/remove/group/:id' , to: 'groups#change_tool', type: 'remove', tool_type: 'Webconference', as: :remove_group_from
      put ':tool_id/add/group/:id'    , to: 'groups#change_tool', type: 'add'   , tool_type: 'Webconference', as: :add_group_to
      get ':tool_id/group/tags'       , to: 'groups#tags'                       , tool_type: 'Webconference', as: :group_tags_from
    end

    member do    
      delete :remove_record, only_recordings: true
      get :access
      get :list_access
      get :user_access
      get :get_record
      put ':id/evaluate' , to: 'academic_allocation_users#evaluate', tool: 'Webconference', as: :evaluate
    end
  end

  resources :exams do
    collection do
      get :list
      get :calcule_all
      put ':tool_id/unbind/group/:id', to: 'groups#change_tool', type: 'unbind', tool_type: 'Exam', as: :unbind_group_from
      put ':tool_id/remove/group/:id', to: 'groups#change_tool', type: 'remove', tool_type: 'Exam', as: :remove_group_from
      put ':tool_id/add/group/:id'   , to: 'groups#change_tool', type: 'add'   , tool_type: 'Exam', as: :add_group_to
      get ':tool_id/group/tags'      , to: 'groups#tags'                       , tool_type: 'Exam', as: :group_tags_from
    end

    member do 
      put :change_status
      get :open
      get :pre, to: 'exams#pre'
      get :preview
      get :result_user, to: :result_exam_user
      get :complete
      get :percentage
      put :calcule_grade
      put :calcule_grade_user
      put ':id/evaluate' , to: 'academic_allocation_users#evaluate', tool: 'Exam', as: :evaluate
    end
  end

  resources :questions do
    collection do
      get :list
      get :search, to: :index
    end

    member do 
      put :change_status
      put :publish, to: :change_status, status: true
      get :verify_owners, update: true
      get :copy_verify_owners, to: :verify_owners, copy: true
      get :show_verify_owners, to: :verify_owners, show: true
      get :copy
    end
  end

  resources :exam_questions do
    member do 
      put "order/:change_id", action: :order, as: :change_order
      put :annul
      get '/export/exam_questions/steps',   to: 'exam_questions#export_steps',   as: :export_steps
      put :publish
      get :copy
      put :remove_image_item
      put :remove_audio_item
    end

    collection do
      get '/import/exam_questions/steps',   to: 'exam_questions#import_steps',   as: :import_steps
      get '/import/exam_questions/list',    to: 'exam_questions#import_list',    as: :import_list
      get '/import/exam_questions/details', to: 'exam_questions#import_details', as: :import_details
      get '/import/exam_questions/preview', to: 'exam_questions#import_preview', as: :import_preview
      put '/import/exam_questions/',        to: 'exam_questions#import',         as: :import

      get '/export/exam_questions/list',    to: 'exam_questions#export_list',    as: :export_list
      get '/export/exam_questions/details', to: 'exam_questions#export_details', as: :export_details
      put '/export/exam_questions/',        to: 'exam_questions#export',         as: :export
    end
  end

  resources :tools, only: [] do
    get :equalities, on: :collection 
  end

  resources :exam_responses, except: [:show]

  resources :assignment_webconferences do
    member do
      delete :remove_record, only_recordings: true
      get :get_record
      put :change_status
    end
  end

  # reports_add
  resources :reports do
    collection do
      get :index
      post :create
      get :render_reports
      get :types_reports
    end
  end


  resources :savs, only: :index, defaults: { format: 'json' }

  match '/select_group', to: 'application#select_group', as: :select_group

  get '/media/lessons/:id/:file(.:extension)', to: 'access_control#lesson_media', index: true
  get '/media/lessons/:id/:folder/*path',    to: 'access_control#lesson_media', index: false

  get '/media/users/:user_id/photos/:style.:extension', to: 'access_control#users'

  get '/media/assignment/sent_assignment_files/:file.:extension', to: 'access_control#assignment'
  get '/media/assignment/comments/:file.:extension',    to: 'access_control#assignment'
  get '/media/assignment/public_area/:file.:extension', to: 'access_control#assignment'
  get '/media/assignment/enunciation/:file.:extension', to: 'access_control#assignment'

  get '/media/bibliography/:file.:extension', to: 'access_control#bibliography'
  get '/media/support_material_files/:file.:extension', to: 'access_control#support_material_file'
  get "/media/messages/:file.:extension", to: "access_control#message"
  # get "/media/discussions/post/:file.:extension", to: "access_control#post"

  get '/media/questions/images/:file.:extension', to: 'access_control#question_image'
  get '/media/questions/items/:file.:extension', to: 'access_control#question_item'
  get '/media/questions/audios/:file.:extension', to: 'access_control#question_audio'

  mount Ckeditor::Engine => '/ckeditor'
  ## como a API vai ser menos usada, fica mais rapido para o solar rodar sem precisar montar essas rotas
  mount ApplicationAPI => '/api'

  use_doorkeeper do
    controllers applications: 'oauth/applications'
  end

end
