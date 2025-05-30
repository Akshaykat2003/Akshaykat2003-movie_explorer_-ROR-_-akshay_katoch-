# spec/swagger_helper.rb
require 'rails_helper'

RSpec.configure do |config|
  config.swagger_root = Rails.root.join('swagger').to_s

  config.swagger_docs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Movie Explorer+ API',
        version: 'v1'
      },
      paths: {},
      servers: [
        { url: 'http://localhost:3000', description: 'Development server' },
        { url: 'https://movie-explorer-rorakshaykat2003-movie.onrender.com', description: 'Production server' } # Update with your Render URL
      ]
    }
  }

  config.swagger_format = :yaml
end