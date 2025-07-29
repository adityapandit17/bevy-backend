Rails.application.routes.draw do
  # Existing resources
  resources :employees
  resources :departments
  resources :job_openings
  resources :leave_requests
  resources :salary_structures
  resources :payrolls
  resources :attendance_records
  resource :company, only: [:show, :update]

  # Onboarding System
  resources :onboarding_employees do
    member do
      patch :update_status
    end
    collection do
      get :stats
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

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
