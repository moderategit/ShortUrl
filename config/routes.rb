Rails.application.routes.draw do
  # Root path
  root "short_urls#index"

  # Short URL resources
  resources :short_urls, only: [:new, :create, :show, :index]

  # Shows visit analytics/report
  get "visits", to: "visits#index", as: :visits_index

  # Dynamic redirect - catch short paths
  get "/:path", to: "short_urls#redirect", as: :short_url_redirect, constraints: { path: /[a-zA-Z0-9_-]{1,15}/ }

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
