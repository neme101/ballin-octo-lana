$LOAD_PATH << __dir__ << File.join(__dir__, "lib")
ENV["RACK_ENV"] ||= "development"

require "bundler"
Bundler.setup(:default, ENV["RACK_ENV"])

module ProxyServer
end


require "cuba"
require "json"

# This is our basic Cuba application. Modifications done to this class will
# affect all our applications, so make sure everything you do here doesn't
# affect performance in inadverted ways.
class ProxyServer::App < Cuba
  # Public: Sends an error to the user. This helper takes into account the
  # current Content-Type and offers an appropriate response.
  #
  # status - An Integer with the desired HTTP response status code.
  # error  - Either an Exception or a String with the error message to show.
  #
  # Returns nothing.
  def send_error(status, error)
    # If the provided error is an Exception-like object, then use its message.
    # If it's a String-like object, then use itself, and if it's neither, then
    # just cast it to a String and hope for the best.
    error = if error.respond_to?(:exception)
              error.exception.message
            elsif error.respond_to?(:to_str)
              error.to_str
            else
              error.to_s
            end

    res.status = status

    on accept("application/json") do
      res.write JSON.dump("error" => { "message" => error })
    end

    on default do
      res["Content-Type"] = "text/plain"
      res.write error
    end
  end

  # Public: Matcher for PATCH requests.
  #
  # Returns Boolean.
  def patch
    req.patch?
  end
end