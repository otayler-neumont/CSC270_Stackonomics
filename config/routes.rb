Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get  "about",   to: "pages#about",   as: :about
  get  "contact", to: "pages#contact", as: :contact
  post "contact", to: "pages#submit_contact", as: :submit_contact

  root "pages#home"
end
