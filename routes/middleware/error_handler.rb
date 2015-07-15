# This middleware takes care of catching errors and submitting them to Your logger (Needs to be coded).
# After that, it re-raises them.
class ProxyServer::ErrorHandler

  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue Exception => err
    raise if development?
    # Report the exception to your favorite exception logger
    # error_response(env)
  end

  # Internal: Requests in the development / test environments should just bubble
  # the exception up.
  #
  # Returns Boolean.
  def development?
    %w(development test).include?(ENV["RACK_ENV"])
  end

  # Internal: Generates an appropriate response for production environments,
  # depending on the requested content type.
  #
  # TODO: We most likely want better error pages, at least for the text/html
  # case :)
  #
  # env - The Rack env.
  #
  # Returns a Rack "Array response".
  def error_response(env)
    mimes = Rack::Utils.q_values(env.fetch("HTTP_ACCEPT", "text/plain"))
    mimes = mimes.sort_by { |_, q| q }.map { |type, _| type }

    mime = mimes.detect(-> { "text/plain" }) do |type|
      %w(text/html text/plain application/json).include?(type)
    end

    message = <<-TEXT.gsub(/^\s+/m, "").gsub("\n", " ")
      Oops! Sorry, we made a mistake and something went wrong.
      We've been notified and our trained squirrels have been dispatched to deal
      with it.
    TEXT

    body = case mime
    when "text/html"
      "<h1>Server Error</h1><p>#{message}</p>"
    when "text/plain"
      "Server Error\n\n#{message}"
    when "application/json"
      %Q|{"error":{"message":"#{message}"}}|
    end

    headers = {
      "Content-Type" => mime,
      "Content-Length" => body.size
    }

    [500, headers, [body]]
  end
end