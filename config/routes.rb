Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "labs#index"

  resources :labs, only: [:index]

  # Board Bootstrap Lab
  resource :board_bootstrap, only: [:new, :create, :show], controller: "board_bootstrap"

  # Process Extractor Lab
  resource :process_extractor, only: [:new, :create, :show], controller: "process_extractor"

  # Bulk Board Delete Lab
  resource :bulk_board_delete, only: [:show], controller: "bulk_board_delete" do
    delete :destroy
  end

  # Movie Recommender Lab
  resource :movie_recommender, only: [:new, :create, :show], controller: "movie_recommender"

  # Book Club Generator Lab
  resource :book_club_generator, only: [:new, :create, :show], controller: "book_club_generator"

  # Gift Idea Generator Lab
  resource :gift_idea_generator, only: [:new, :create, :show], controller: "gift_idea_generator"

  # Restaurant Bucket List Lab
  resource :restaurant_bucket_list, only: [:new, :create, :show], controller: "restaurant_bucket_list"

  # Learning Path Creator Lab
  resource :learning_path_creator, only: [:new, :create, :show], controller: "learning_path_creator"
end
