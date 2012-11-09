Blog::Application.routes.draw do
  resources :articles
  root to: 'main#index'
end
