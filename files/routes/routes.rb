ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"
  

  # SILK ROUTES

  # Home Page
  map.root :controller => 'silk/pages', :action => 'show'
  
  # Authentication restful rewrites
  map.login  '/login',  :controller => 'silk/sessions', :action => 'new'
  map.logout '/logout', :controller => 'silk/sessions', :action => 'destroy'  
  
  # Allow admin access to Silk controllers
  map.namespace :silk do |silk|
    silk.resources :pages
    silk.resources :content
    silk.resource :sessions
  end
  
  # First try searching for a real page (hard-coded Rails view)
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
  # If no view found, look for an existing page in the database
  # If the page doesn't exist and user is logged in they will be prompted to create it
  map.page_route '*page_path', :controller => 'silk/pages', :action => 'show'

end
