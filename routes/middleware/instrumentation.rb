require "rack/runtime"

# Instrument a Rack application with these middleware. This sets the X-Runtime
# header (via Rack::Runtime).
class ProxyServer::Instrumentation
  def initialize(app)
    stack = Rack::Builder.new
    stack.use Rack::Runtime
    stack.run app
    @app = stack.to_app
  end

  def call(env)
    @app.call(env)
  end
end