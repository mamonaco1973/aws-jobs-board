Rails.application.routes.draw do
  devise_for :users

  root "jobs#index"

  resources :jobs, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    resources :applications, only: [:new, :create]
  end

  resources :companies, only: [:show, :new, :create, :edit, :update]

  namespace :employer do
    root "jobs#index"
    resources :jobs, only: [:index, :show] do
      resources :applications, only: [:show] do
        member do
          patch :update_status
        end
      end
    end
  end

  get "dashboard", to: "dashboard#index", as: :dashboard
end
