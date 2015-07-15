require "rack/protection"
require "better_errors" if ENV["RACK_ENV"] == "development"
require "pry" if ENV["RACK_ENV"] == "development"
require "routes/middleware/error_handler"
require "routes/middleware/instrumentation"

class ProxyServer::Root < ProxyServer::App
  use ProxyServer::Instrumentation
  use Rack::Deflater

  use BetterErrors::Middleware if defined?(BetterErrors)
  use ProxyServer::ErrorHandler

  # FIXME: We can't use Rack::Protection just like that because it depends on
  # sessions being present (which we won't have in the API, for example). Thus,
  # we're just including some modules that don't require any rack session set.
  #
  # Once we have a clearer picture of how we're handling sessions we can hook up
  # this middleware at the appropriate place and make sure we have as many
  # protections set up as possible.
  use Rack::Protection::FrameOptions
  use Rack::Protection::HttpOrigin
  use Rack::Protection::IPSpoofing
  use Rack::Protection::PathTraversal
  use Rack::Protection::RemoteReferrer
  use Rack::Protection::XSSHeader

  use Rack::MethodOverride

  define do
    on "sportngin" do
      on "ussa" do
        on param("user"), param("token") do |user, token|
          on "member-info", param("ussaId") do |ussa_id|
            begin
              request = ussa_prepare_request('member-info', user, token, ussaId: ussa_id)
              req = request[:req]
              uri = request[:uri]

              response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
                http.request(req)
              end

              res.write response.read_body # this raises an HTTPError exception if the response.code is not 2xx
            rescue => e
              send_error 400, e
            end
          end

          on "member-search", param("firstName"), param("lastName") do |first_name, last_name|
            begin
              request = ussa_prepare_request('member-search', user, token, firstName: first_name, lastName: last_name)
              req = request[:req]
              uri = request[:uri]

              response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
                http.request(req)
              end

              res.write response.read_body # this raises an HTTPError exception if the response.code is not 2xx
            rescue => e
              send_error 400, e
            end
          end
        end
      end
    end

    on true do
      res.write "Don't know why you bothered..."
    end
  end

  def ussa_prepare_request(endpoint, user, token, params)
    require 'net/http'
    require 'json'

    uri = URI("https://my.ussa.org/api/services/#{endpoint}")
    req = Net::HTTP::Post.new(uri.request_uri)

    default_params = {'user' => user, 'token' => token, 'format' => 'json'}
    data = default_params.merge(params)

    req.set_form_data(data)

    {uri: uri, req: req}
  end
end
