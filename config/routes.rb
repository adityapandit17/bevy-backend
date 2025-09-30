Rails.application.routes.draw do
  # API Routes
  namespace :api do
    namespace :v1 do
      # JWT Authentication routes
      post "auth/login", to: "auth#login"
      post "auth/logout", to: "auth#logout"
      post "auth/refresh", to: "auth#refresh"
      get "auth/me", to: "auth#me"
      post "auth/validate", to: "auth#validate"
    end
  end

  get "super_admin/dashboard"
  get "super_admin/system_logs"
  get "super_admin/audit_trails"
  get "super_admin/system_health"
  get "super_admin/database_management"
  get "super_admin/backup_restore"
  get "super_admin/user_activity"
  get "super_admin/security_settings"
  get "super_admin/system_configuration"
  get "super_admin/maintenance_mode"
  # Custom session routes
  post "/sessions", to: "sessions#create"
  delete "/sessions", to: "sessions#destroy"
  get "/sessions/current", to: "sessions#current"

  # Dashboard route
  get "/dashboard", to: "dashboard#index"


  # Test route
  get "/test/auth", to: "test#auth_test"

  resources :users do
    member do
      patch :update_roles
    end
  end

  resources :roles do
    member do
      patch :update_permissions
      get :permissions_matrix
      patch :toggle_permission
      post :add_default_module_permissions
      post :add_permission
    end
  end

  resources :permissions

  # Super Admin Routes
  namespace :super_admin do
    get :dashboard
    get :system_logs
    get :audit_trails
    get :system_health
    get :database_management
    get :backup_restore
    post :create_backup
    get :user_activity
    get :security_settings
    put :update_security_settings
    get :system_configuration
    put :update_system_configuration
    get :maintenance_mode
    post :toggle_maintenance_mode
  end
  # Employee Profile System
  resources :employee_profiles, only: [ :show ] do
    member do
      get :overview
      get :job_details
      get :time_off
      get :pay_info
      get :documents
      get :performance
      get :timesheets
      get :benefits
      get :training
      get :assets
    end
  end

  # Employee Documents
  resources :employee_documents do
    collection do
      get :by_employee
      get :expiring_soon
    end
  end

  # Performance Management
  resources :performance_reviews do
    collection do
      get :by_employee
      get :stats
    end
  end

  resources :performance_goals do
    member do
      patch :update_progress
    end
    collection do
      get :by_employee
      get :overdue
      get :due_soon
    end
  end

  # Timesheets
  resources :timesheets do
    member do
      patch :approve
      patch :reject
    end
    collection do
      get :by_employee
      get :this_week
      get :this_month
      get :stats
    end
  end

  # Employee Benefits
  resources :employee_benefits do
    collection do
      get :by_employee
      get :expiring_soon
      get :stats
    end
  end

  # Employee Training
  resources :employee_trainings do
    member do
      patch :update_progress
      patch :complete
      patch :cancel
    end
    collection do
      get :by_employee
      get :current
      get :upcoming
      get :stats
    end
  end

  # Existing resources
  resources :employees
  resources :departments
  resources :job_openings
  resources :leave_requests do
    member do
      patch :approve
      patch :reject
      patch :cancel
    end
    collection do
      get :balance
      get :calendar
      get :stats
      get :approvers
    end
  end
  resources :salary_structures
  resources :payrolls
  resources :attendance_records do
    member do
      patch :check_in
      patch :check_out
    end
    collection do
      get :today
      get :stats
      get :calendar
    end
  end
  resource :company, only: [ :show, :update ]

  # Onboarding System
  resources :onboarding_employees do
    member do
      patch :update_status
    end
    collection do
      get :stats
      get :check_employee, path: "check_employee/:employee_id"
    end
  end

  resources :onboarding_tasks do
    member do
      patch :toggle
    end
    collection do
      get :overdue
      get :due_soon
    end
  end

  # Offboarding System
  resources :offboarding_employees do
    member do
      patch :update_status
    end
    collection do
      get :stats
    end
  end

  resources :offboarding_tasks do
    member do
      patch :toggle
    end
    collection do
      get :overdue
      get :due_soon
      get :by_employee
      get :stats
    end
  end

  # ATS System
  resources :candidates do
    member do
      patch :update_status
    end
    collection do
      get :stats
      get :pipeline
    end
  end

  resources :interviews do
    member do
      patch :complete
      patch :cancel
      patch :no_show
    end
    collection do
      get :stats
      get :calendar
    end
  end

  # Asset Management System
  resources :assets do
    collection do
      get :stats
      get :allocations
      get :maintenance
    end
  end

  resources :asset_allocations do
    member do
      patch :return
    end
  end

  resources :maintenance_records do
    collection do
      post :schedule
    end
  end

  # File Upload System
  resources :uploads, only: [:create] do
    collection do
      get ':filename', to: 'uploads#show', as: :file
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
