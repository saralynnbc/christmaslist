Rails.application.routes.draw do
  devise_for :users, controllers: {registrations: 'users/registrations'}

  resources :wards, except: [:show]

  resources :lists, only: [] do
    resources :items, except: [:show]
  end

  resources :groups do
    resources :invitations
    resources :lists, only: [] do
      resources :items, only: [:index, :new, :create, :destroy] do
        post :purchase
        post :unpurchase
      end
    end
    get :purchases
  end

  root to: "home#index"
end
