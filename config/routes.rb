Rails.application.routes.draw do
  # Membership (Phase 5): sessions + sign-up. Session is the login/logout pair;
  # registration is the sign-up pair. Password reset was intentionally left out
  # (no mailer in this deploy) to keep the demo bug-free.
  resource  :session, only: %i[new create destroy]
  resource  :registration, only: %i[new create]

  get "up" => "rails/health#show", as: :rails_health_check

  # JSON API is now read-only: the DAL still serves specimens as JSON (the
  # Phase 3/4 narrative) but every mutation goes through the authenticated
  # HTML controllers below so ownership rules can't be bypassed.
  namespace :api do
    resources :specimens, only: %i[index show]
  end

  resources :specimens do
    member do
      get :delete_confirm, path: "delete"
    end
    resources :comments, only: %i[create destroy]
    resource  :like, only: %i[create destroy]
  end

  # Public profile == that member's collection.
  resources :users, only: %i[show]

  get  "gems",   to: "pages#gems",   as: :gems
  get  "metals", to: "pages#metals", as: :metals
  get  "mines",  to: "pages#mines",  as: :mines

  post "tips", to: "pages#submit_tip", as: :submit_tip

  root "pages#home"
end
