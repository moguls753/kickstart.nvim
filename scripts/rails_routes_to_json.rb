# save_routes_to_json.rb
# require 'rails'
# require 'json'
require './config/environment'

routes = Rails.application.routes.routes.map do |route|
  next unless route.name

  {
    route: route.name
  }
end.compact

puts routes.to_json
