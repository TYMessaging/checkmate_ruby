require 'checkmate_ruby/configuration'
require 'checkmate_ruby/property'
require 'json'
require 'typhoeus'

module Checkmate
  class Client
    include Typhoeus
    extend Configuration

    attr_accessor *Configuration::VALID_OPTIONS

    def initialize(options = {})
      merged_options = Checkmate::Client.options.merge(options)
      Configuration::VALID_OPTIONS.each do |key|
        public_send("#{key}=", merged_options[key])
      end
    end

    def get_property(property_params)
      property = Checkmate::Property.new(property_params)
      request = create_request("get", property)
      handle_response(request.run)
    end

    private
      def create_request(method, resource)
        Request.new(
          specific_uri(resource),
          method: method.to_sym,
          params: resource.to_uri_params,
          headers: headers,
          followlocation: true)
      end

      def headers
        headers = {
          "Accept" => "application/json",
          "X-CheckMate-API-Token" => private_key
        }
      end

      def handle_response(response)
        if response.success?
          JSON.parse(response.body)
        else
          {:code => response.code,
            :message => response.status_message}
        end
      end

      def specific_uri(resource)
        api_url + resource.uri_path
      end
    end
end
