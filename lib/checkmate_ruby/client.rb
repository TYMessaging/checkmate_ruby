require 'checkmate_ruby/configuration'
require 'checkmate_ruby/property_params'
require 'checkmate_ruby/reservation_params'
require 'checkmate_ruby/reservations_params'
require 'json'
require 'hashie/mash'
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
      property_params = Checkmate::PropertyParams.new(property_params)
      request = create_request("get", property_params)
      handle_response(request.run)
    end

    def list_reservations(reservations_params = {})
      reservations_params = Checkmate::ReservationsParams.new(reservations_params)
      request = create_request("get", reservations_params)
      handle_response(request.run) 
    end

    def show_reservation(reservation_id)
      reservations_params = Checkmate::ReservationsParams.new({:reservation_id => reservation_id})
      request = create_request("get", reservations_params)
      handle_response(request.run) 
    end

    def create_reservation(reservation_params, property_id = nil)
      reservation_params = Checkmate::ReservationParams.new(reservation_params, property_id)
      request = create_request("put", reservation_params)
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
          Hashie::Mash.new(JSON.parse(response.body))
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
