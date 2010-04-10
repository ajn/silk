module Silk
  module Routes
    def self.apply!(route_set, &block)
      mapper = ActionDispatch::Routing::Mapper.new(route_set)
      mapper.instance_exec do
        namespace :silk do
          resources :pages
          resources :content, :controller => 'content'
          resource :sessions
        end

        match '/silk/login' => 'silk/sessions#new', :as => :silk_login
        match '/silk/logout' => 'silk/sessions#destroy', :as => :silk_logout
      end
      
      if block.arity == 1
        deprecated_mapper = ActionDispatch::Routing::DeprecatedMapper.new(route_set)
        mapper.instance_exec(deprecated_mapper, &block)
      else
        mapper.instance_exec(&block)
      end
      
      mapper.instance_exec do
        match '*page_path' => 'silk/pages#show', :as => :silk_page_route
        root :to => 'silk/pages#show'
      end
    end
  end
end