App::Application.routes.draw do

  namespace :admin do
      resources :purchases
      resources :suppliers
    end

end
