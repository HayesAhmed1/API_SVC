module Namely
  class ResourceGateway
    attr_reader :endpoint

    def initialize(options)
      @access_token = options.fetch(:access_token)
      @endpoint = options.fetch(:endpoint)
      @subdomain = options.fetch(:subdomain)
      @paged = options.fetch(:paged, false)
    end

    def json_index
      paged ? json_index_paged : json_index_all
    end

    def json_show(id)
      get("/#{endpoint}/#{id}")[resource_name].first
    end

    def show_head(id)
      head("/#{endpoint}/#{id}")
    end

    def create(attributes)
      response = post(
        "/#{endpoint}",
        endpoint => [attributes]
      )
      extract_id(response)
    end

    def update(id, changes)
      put("/#{endpoint}/#{id}", endpoint => [changes])
    end

    private

    def json_index_all
      get("/#{endpoint}", limit: :all)[resource_name]
    end

    def json_index_paged
      Enumerator.new do |y|
        params = {}

        loop do
          objects = get("/#{endpoint}", params)[resource_name]
          break if objects.empty?

          objects.each { |o| y << o }

          params[:after] = objects.last["id"]
        end
      end
    end

    attr_reader :access_token, :subdomain, :paged

    def resource_name
      endpoint.split("/").last
    end

    def url(path)
      "https://#{subdomain}.namely.com/api/v1#{path}"
    end

    def extract_id(response)
      JSON.parse(response.body)[endpoint].first["id"]
    rescue StandardError => e
      raise(
        "#{JSON.parse(response.body)['errors']}"
      )
    end

    def get(path, params = {})
      response = HTTParty.get(url(path),
        headers: { accept: "application/json", content_type: "application/json", authorization: "Bearer #{access_token}" }
      )

      JSON.parse(response.body)
    end

    def head(path, params = {})
      params.merge!(access_token: access_token)
      RestClient.head(url(path), accept: :json, params: params)
    end

    def post(path, params)
      response = HTTParty.post(url(path),
        body: params,
        headers: { accept: 'application/json', content_type: 'application/json', authorization: "Bearer #{access_token}" }
      )
    end

    def put(path, params)
      response = HTTParty.post(url(path),
        body: params,
        headers: { accept: 'application/json', content_type: 'application/json', authorization: "Bearer #{access_token}" }
      )
    end
  end
end
