# frozen_string_literal: true

json.id vehicle.id
json.name vehicle.name
json.purchased vehicle.purchased
json.flagship vehicle.flagship
json.sale_notify vehicle.sale_notify
json.model do
  json.partial! 'api/v1/models/minimal', model: vehicle.model
end
json.user do
  json.partial! 'api/v1/users/base', user: vehicle.user
end
json.partial! 'api/shared/dates', record: vehicle
