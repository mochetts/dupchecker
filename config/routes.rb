Rails.application.routes.draw do
  root to: "posts#new"
  resources :posts, only: [:new, :create]
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  resources :duplicate_checks, only: [:create]
end
