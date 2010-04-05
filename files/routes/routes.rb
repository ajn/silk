YourApp::Application.routes.draw do

  namespace :silk do
    resources :pages
    resources :content, :controller => 'content'
    resource :sessions
  end
  
  root :to => 'silk/pages#show'

  match '/login' => 'silk/sessions#new', :as => :login
  match '/logout' => 'silk/sessions#destroy', :as => :logout

  match '*page_path' => 'silk/pages#show', :as => :page_route

end
