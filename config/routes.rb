Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    resources :specimens, only: %i[index show create update destroy]
  end

  get  "specimens",              to: "specimens#index",          as: :specimens
  get  "specimens/new",          to: "specimens#new",            as: :new_specimen
  get  "specimens/delete/:id",   to: "specimens#delete_confirm", as: :delete_specimen
  get  "specimens/:id/edit",     to: "specimens#edit",           as: :edit_specimen
  get  "specimens/:id",          to: "specimens#show",           as: :specimen

  get  "gems",   to: "pages#gems",   as: :gems
  get  "metals", to: "pages#metals", as: :metals
  get  "mines",  to: "pages#mines",  as: :mines

  post "tips", to: "pages#submit_tip", as: :submit_tip

  root "pages#home"
end
