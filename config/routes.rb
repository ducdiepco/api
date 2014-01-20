require 'resque/server'

Fleetyards::Application.routes.draw do
  devise_for :users, skip: [:sessions], controllers: { registrations: "registrations" }

  namespace :backend do
    put '/locales/fetch' => 'locales#fetch', as: :update_locales

    resources :users, except: [:show]

    resources :settings, except: [:index, :show]

    authenticate :user, lambda {|u| u.admin? } do
      mount Resque::Server.new, :at => "/workers"
    end

    root 'base#index'
  end

  as :user do
    get 'register' => 'registrations#new', as: :new_registration
    get 'login' => 'sessions#new', as: :new_user_session
    post 'login' => 'sessions#create', as: :user_session
    delete 'logout' => 'sessions#destroy', as: :destroy_user_session
  end

  resource :password, only: [:edit, :update]

  resources :ships, param: :slug do
    collection do
      put 'reload'
    end
  end

  resources :weapons, only: [:index]
  resources :equipments, only: [:index]

  resources :manufacturers, param: :slug

  resources :ship_roles, param: :slug

  get 'worker/:name/check' => 'worker#check_state', as: :check_worker_state

  get 'impressum' => 'base#impressum'

  root 'base#index'
end
