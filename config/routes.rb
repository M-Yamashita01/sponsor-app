Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  scope path: 'admin', module: 'admin' do
    get '/' => 'dashboard#index', as: :dashboard
    resources :conferences, param: :slug do
      resources :form_descriptions, except: %i(index)
      resources :plans, except: %i(index show)
      resources :sponsorships, except: %i(index new create destroy) do
        resources :sponsorship_editing_histories, as: :editing_histories, path: 'editing_history', only: %i(index)
        member do
          get :download_asset
        end
      end
    end
    resource :session, only: %i(new destroy) do
      get :rise, as: :rise
    end
  end
  get '/auth/:provider/callback' => 'admin/sessions#create'

  get '/' => 'root#index'

  scope as: :user do
    resource :session, only: %i(new create destroy) do
      get 'claim/:handle', action: :claim, as: :claim
    end

    resources :conferences, param: :slug, only: %i(index) do
      resource :sponsorship, only: %i(new create show edit update)
      resource :sponsorship_asset_file, only: %i(create update)
    end
  end

  get '/site/sha' => RevisionPlate::App.new(File.join(__dir__, '..', 'REVISION'))
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
