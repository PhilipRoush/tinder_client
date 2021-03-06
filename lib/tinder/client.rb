# frozen_string_literal: true

require "tinder_client"
require "faraday"

module Tinder

  class Client
    # Always prefer V2 endpoints as the API is less buggy than V1
    BASE_URI  = 'https://api.gotinder.com'
    ENDPOINTS = {
      request_code:    "/v2/auth/sms/send?auth_type=sms",
      login:           "/v2/auth/login/sms",
      validate:        "/v2/auth/sms/validate?auth_type=sms",
      recommendations: "/v2/recs/core",
      updates:         "/updates"
    }

    attr_accessor :api_token
    attr_accessor :refresh_token

    def post(url, **data)
      response = Faraday.post(url, JSON.generate(data), headers)
      JSON.parse(response.body) unless response.body.nil?
    end

    def get(url, **data)
      # GET requests won't get a response using JSON
      response = Faraday.get(url, data, headers)
      JSON.parse(response.body) unless response.body.nil?
    end

    # @param phone_number String
    def request_code(phone_number)
      response = post(endpoint(:request_code), phone_number: phone_number)
      response.dig('data', 'sms_sent') || fail(UnexpectedResponse(response))
    end

    # @param phone_number String Your phone number
    # @param confirmation_code String The code sent to your phone
    # @return String Named 'refresh token', this is one part of the 2-part authentication keys
    def validate(phone_number, confirmation_code)
      data = { otp_code:     confirmation_code,
               phone_number: phone_number,
               is_update:    false }

      response       = post(endpoint(:validate), data)
      @refresh_token = response.dig('data', 'refresh_token') || fail(UnexpectedResponse(response))
    end

    # @param phone_number String Your phone number
    # @param confirmation_code String The code sent to your phone
    # @return String The API key
    def login(phone_number, refresh_token)
      data     = { refresh_token: refresh_token, phone_number: phone_number }
      response = post(endpoint(:login), data)

      @api_token   = response.dig('data', 'api_token') || fail(UnexpectedResponse(response))
      @id          = response['data']['_id']
      @is_new_user = response['data']['is_new_user']
      @api_token
    end

    def endpoint(action)
      "#{BASE_URI}#{ENDPOINTS[action]}"
    end

    protected

    def headers
      {
        "app_version":  "6.9.4",
        "platform":     "ios",
        "content-type": "application/json",
        "User-agent":   "Tinder/7.5.3 (iPhone; iOS 10.3.2; Scale/2.00)",
        "Accept":       "application/json",
        "X-Auth-Token": api_token
      }
    end

  end
end
