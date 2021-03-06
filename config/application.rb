require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module NotifstaWebapp
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # turn off warnings triggered by friendly_id
    I18n.enforce_available_locales = false

    # load sidekiq workers
    config.autoload_paths += %W(#{config.root}/app/workers)

    # load Notifications through inheritance (messages and surveys)
    config.autoload_paths += %W(#{config.root}/app/models/notifications)

    # Test framework
    config.generators.test_framework false

    # autoload lib path
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]

    # allow everything through CORS. Very insecure. Should be fixed.
    config.action_dispatch.default_headers.merge!({
      'Access-Control-Allow-Origin' => '*',
      'Access-Control-Request-Method' => '*',
      'Access-Control-Allow-Methods' => 'POST, GET, OPTIONS, PATCH, DELETE'
    })

    # disable rack lock for websockets
    config.middleware.delete Rack::Lock

    # React options
    config.react.jsx_transform_options = {
      harmony: true
    }

    config.middleware.insert_before 0, "Rack::Cors" do
      allow do
        origins '*'
        resource '*', :headers => :any, :methods => [:get, :post, :options]
      end
    end

    # opt in to errors in callbacks
    config.active_record.raise_in_transactional_callbacks = true
  end
end
