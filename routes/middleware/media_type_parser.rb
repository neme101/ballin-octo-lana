class ProxyServer::MediaTypeParser
  # Internal: The structure of our API media types.
  FORMAT = %r{\A
    (?<mime_base>(?:x-)?\w+)    # Mime-Type base
    /
    vnd\.cubalibre\.             # Vendor namespace
    (?<version>v\d+)            # Version
    (?<options>(\.\w+)*)        # Extra options
    \+
    (?<mime_type>(?:x-)?\w+)    # Content-Type
  \z}x.freeze

  # Internal: Get the version parsed from the media type, if applicable.
  attr_reader :version

  # Internal: Get the content type parsed from the media type, if applicable.
  attr_reader :content_type

  # Internal: Get any options parsed out of the media type, if applicable.
  attr_reader :media_type_options

  # Public: Initialize the middleware.
  #
  # app - The upstream Rack app.
  def initialize(app)
    @app = app
  end

  # Public: Parse the media type and assign any options necessary. This should
  # extract:
  #
  # * `app.api.version`: The requested API version (such as "v4").
  # * `app.api.media-type-options`: An Array with any extra options passed in
  #   the media type.
  # * `HTTP_ACCEPT`: If we parsed the requested HTTP_ACCEPT, then this
  #   middleware will reset it to a simple MIME type, based on the parsed one
  #   (such as "application/json" for "application/vnd.cubalibre.v4+json").
  #
  # env - The Rack env.
  #
  # Returns a Rack response Array.
  def call(env)
    if scan_accept_header(env["HTTP_ACCEPT"])
      env["app.api.version"] = version
      env["app.api.media-type-options"] = media_type_options
      env["HTTP_ACCEPT"] = content_type
    end

    @app.call(env)
  end

  # Internal: Actually parse the information out of the Accept HTTP Header.
  #
  # accept - A String with the Accept HTTP Header.
  #
  # Returns Boolean, depending on whether `accept` matches our vendor type.
  def scan_accept_header(accept)
    if match = accept.match(FORMAT)
      @version = match[:version]
      @content_type = [match[:mime_base], match[:mime_type]].join("/")
      @media_type_options = match[:options].scan(/(\.\w+)/).map do |option|
        option.first.sub!(/^\./, "")
      end
    end
  end
end