Rails.application.routes.draw do
  root to: "users#index"
  resources :users, except: [:create, :new]
  devise_for :users, path: '', controllers: { omniauth_callbacks: "omniauth_callbacks" }
end
