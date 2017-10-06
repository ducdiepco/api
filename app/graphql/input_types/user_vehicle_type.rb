# frozen_string_literal: true

InputTypes::UserVehicleType = ::GraphQL::InputObjectType.define do
  name 'UserVehicleInput'

  argument :name, types.String
  argument :purchased, types.Boolean
  argument :saleNotify, types.Boolean, as: :sale_notify
end
