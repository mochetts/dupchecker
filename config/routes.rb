Rails.application.routes.draw do
  root to: "posts#new"
  resources :posts, only: [:new, :create]
end
