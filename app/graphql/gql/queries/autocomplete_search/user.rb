# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::User < BaseQuery

    description 'Search for users'

    argument :input, Gql::Types::Input::AutocompleteSearch::InputType, required: true, description: 'The input object for the autocomplete search'

    type [Gql::Types::AutocompleteSearch::UserEntryType], null: false

    def resolve(input:)
      input = input.to_h
      query = input[:query]
      limit = input[:limit] || 50

      return [] if query.strip.empty?

      Service::Search.new(current_user: context.current_user).execute(
        term:    query,
        objects: [::User],
        options: { limit: limit },
      ).map { |user| coerce_to_result(user) }
    end

    def coerce_to_result(user)
      {
        value:   user.id,
        label:   user.fullname,
        heading: user.organization&.name,
        user:    user,
      }
    end
  end
end
