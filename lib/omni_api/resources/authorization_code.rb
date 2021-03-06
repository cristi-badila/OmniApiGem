require_relative 'base_client_model'

module OmniApi
  module Resources
    class AuthorizationCode < BaseClientModel
      include OmniApi::Concerns::Timestamps

      attr_accessible :id, :code
    end
  end
end