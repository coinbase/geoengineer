########################################################################
# GeoEngineer::ApiGatewayHelpers Utility methods for ApiGateway resources
#
########################################################################
module GeoEngineer::ApiGatewayHelpers
  def self._base_path_mapping_cache
    @_base_path_mapping_cache ||= {}
    @_base_path_mapping_cache
  end

  def self._domain_name_cache
    @_domain_name_cache ||= {}
    @_domain_name_cache
  end

  def self._rest_api_cache
    @_rest_api_cache ||= {}
    @_rest_api_cache
  end

  def self._rest_api_resource_cache
    @_rest_api_resource_cache ||= {}
    @_rest_api_resource_cache
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  # Class Methods
  module ClassMethods
    # Helper Client
    def _client(provider)
      AwsClients.api_gateway(provider)
    end

    # Base Path Mapping
    def _fetch_remote_base_path_mappings(provider)
      cache = GeoEngineer::ApiGatewayHelpers._base_path_mapping_cache
      return cache[provider] if cache[provider]

      ret = _client(provider).get_domain_names.map(&:items).flatten.map do |d|
        _client(provider).get_base_path_mappings({ domain_name: d.domain_name }).map(&:items).flatten.map(&:to_h).map do |rr|
          rr[:stage_name]       = rr[:stage]
          rr[:api_id]           = rr[:rest_api_id]
          rr[:_terraform_id]    = "#{d.domain_name}/#{rr[:base_path]}"
          rr[:_geo_id]          = "#{rr[:rest_api_id]}::#{rr[:stage]}::#{rr[:base_path]}"
          rr
        end
      end.compact.flatten
      cache[provider] = ret
      ret
    end

    # Domain Name
    def _fetch_remote_domain_names(provider)
      cache = GeoEngineer::ApiGatewayHelpers._domain_name_cache
      return cache[provider] if cache[provider]

      ret = _client(provider).get_domain_names.map(&:items).flatten.map(&:to_h).map do |rr|
        rr[:_terraform_id]    = rr[:domain_name]
        rr[:_geo_id]          = rr[:domain_name]
        rr
      end.compact
      cache[provider] = ret
      ret
    end

    # Rest API
    def _fetch_remote_rest_apis(provider)
      cache = GeoEngineer::ApiGatewayHelpers._rest_api_cache
      return cache[provider] if cache[provider]

      # TODO: This should be paginated by looking at the position parameter returned
      #       See: https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/APIGateway/Client.html#get_rest_apis-instance_method
      ret = _client(provider).get_rest_apis({ limit: 500 })['items'].map(&:to_h).map do |rr|
        rr[:_terraform_id]    = rr[:id]
        rr[:_geo_id]          = rr[:name]
        rr[:root_resource_id] = _root_resource_id(provider, rr)
        rr
      end.compact
      cache[provider] = ret
      ret
    end

    def _root_resource_id(provider, rr)
      _client(provider).get_resources({ rest_api_id: rr[:id] })['items'].map do |res|
        return res.id if res.path == '/'
      end
      nil
    end

    def __fetch_remote_rest_api_resources_for_rest_api(provider, rr)
      _client(provider).get_resources({
                                        rest_api_id: rr[:_terraform_id]
                                      })['items'].map(&:to_h).map do |res|
        next nil unless res[:path_part] # default resource has no path_part

        # The geo id is the full path of the resource, anchored at the root API gateway, with slashes
        # replaced with a double colon delimiter.
        res[:_terraform_id] = res[:id]
        res[:_geo_id]       = "#{rr[:_geo_id]}#{res[:path].gsub('/', '::')}"
        res
      end.compact
    end

    # Resources
    def _fetch_remote_rest_api_resources_for_rest_api(provider, rr)
      cache = GeoEngineer::ApiGatewayHelpers._rest_api_resource_cache[provider] ||= {}
      return cache[rr[:_terraform_id]] if cache[rr[:_terraform_id]]

      cache[rr[:_terraform_id]] = __fetch_remote_rest_api_resources_for_rest_api(provider, rr)
    end

    # Combination Methods
    def _remote_rest_api_resource(provider)
      _fetch_remote_rest_apis(provider).map do |rr|
        _fetch_remote_rest_api_resources_for_rest_api(provider, rr).map do |res|
          yield rr, res
        end
      end
    end

    def _remote_rest_api_resource_method(provider)
      _remote_rest_api_resource(provider) do |rr, res|
        (res[:resource_methods] || {}).keys.map do |meth|
          yield rr, res, meth
        end
      end
    end

    # Integration
    def _fetch_integration(provider, rr, res, meth)
      return _client(provider).get_integration({
                                                 rest_api_id: rr[:_terraform_id],
                                                 resource_id: res[:_terraform_id],
                                                 http_method: meth
                                               }).to_h
    rescue Aws::APIGateway::Errors::NotFoundException
      return nil
    end

    # Method
    def _fetch_method(provider, rr, res, meth)
      return _client(provider).get_method({
                                            rest_api_id: rr[:_terraform_id],
                                            resource_id: res[:_terraform_id],
                                            http_method: meth
                                          }).to_h
    rescue Aws::APIGateway::Errors::NotFoundException
      return nil
    end

    # Models
    def _fetch_remote_rest_api_models(provider, rest_api)
      resources = _client(provider).get_models(
        { rest_api_id: rest_api[:_terraform_id] }
      )['items']
      resources.map(&:to_h).map do |mod|
        mod[:_terraform_id] = mod[:id]
        mod[:_geo_id]       = "#{rest_api[:_geo_id]}::#{mod[:name]}"
        mod
      end.compact
    end

    def _remote_rest_api_models(provider)
      _fetch_remote_rest_apis(provider).map do |rr|
        _fetch_remote_rest_api_models(provider, rr) do |model|
          yield rr, model
        end
      end
    end

    # Request Validators
    def _fetch_remote_rest_api_request_validators(provider, rest_api)
      resources = _client(provider).get_request_validators(
        { rest_api_id: rest_api[:_terraform_id] }
      )['items']
      resources.map(&:to_h).map do |rv|
        rv[:_terraform_id] = rv[:id]
        rv[:_geo_id]       = "#{rest_api[:_geo_id]}::#{rv[:name]}"
        rv
      end
    end

    def _remote_rest_api_request_validators(provider)
      _fetch_remote_rest_apis(provider).map do |rr|
        _fetch_remote_rest_api_request_validators(provider, rr) do |rv|
          yield rr, rv
        end
      end
    end

    # Gateway Responses
    def _fetch_remote_rest_api_gateway_responses(provider, rest_api)
      resources = _client(provider).get_gateway_responses(
        { rest_api_id: rest_api[:_terraform_id] }
      )['items']
      resources.map(&:to_h).map do |gr|
        gr[:_terraform_id] = gr[:id]
        gr[:_geo_id]       = "#{rest_api[:_geo_id]}::#{gr[:response_type]}"
        gr
      end
    end

    def _remote_rest_api_gateway_responses(provider)
      _fetch_remote_rest_apis(provider).map do |rr|
        _fetch_remote_rest_api_gateway_responses(provider, rr) do |gr|
          yield rr, gr
        end
      end
    end

    def _fetch_remote_rest_api_authorizers(provider, rest_api)
      resources = _client(provider).get_authorizers(
        { rest_api_id: rest_api[:_terraform_id] }
      )['items']
      resources.map(&:to_h).map do |ga|
        ga[:_terraform_id] = ga[:id]
        ga[:_geo_id]       = "#{rest_api[:_geo_id]}::#{ga[:name]}"
        ga
      end
    end

    def _remote_rest_api_gateway_authorizers(provider)
      _fetch_remote_rest_apis(provider).map do |rr|
        _fetch_remote_rest_api_authorizers(provider, rr) do |ga|
          yield rr, ga
        end
      end
    end
  end
end
