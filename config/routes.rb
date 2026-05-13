Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get  "gems",   to: "pages#gems",   as: :gems
  get  "metals", to: "pages#metals", as: :metals
  get  "mines",  to: "pages#mines",  as: :mines

  post "tips", to: "pages#submit_tip", as: :submit_tip

  root "pages#home"
end
