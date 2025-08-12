# frozen_string_literal: true

# Suppress Sass deprecation warnings from Bootstrap
# These warnings come from Bootstrap's own SCSS files and will be fixed in future Bootstrap versions

# For Rails with dartsass-rails, we can configure Sass options
if defined?(DartSass) && Rails.env.development?
  Rails.application.config.dartsass.builds = {
    'application.bootstrap.scss' => 'application.css'
  }
  Rails.application.config.dartsass.build_options << '--quiet-deps'
end
