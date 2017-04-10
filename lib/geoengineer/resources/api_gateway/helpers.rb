########################################################################
# GeoEngineer::ApiGatewayHelpers Utility methods for ApiGateway resources
#
########################################################################
module GeoEngineer::ApiGatewayHelpers
  def self.included(base)
    base.extend(ClassMethods)
  end

  # Class Methods
  module ClassMethods
    # Helper Client
    def _client(provider)
      AwsClients.api_gateway(provider)
    end

    # Rest API
    def _fetch_remote_rest_apis(provider)
      _client(provider).get_rest_apis['items'].map(&:to_h).map do |rr|
        rr[:_terraform_id]    = rr[:id]
        rr[:_geo_id]          = rr[:name]
        rr[:root_resource_id] = _root_resource_id(provider, rr)
        rr
      end
    end

    def _root_resource_id(provider, rr)
      _client(provider).get_resources({ rest_api_id: rr[:id] })['items'].map do |res|
        return res.id if res.path == '/'
      end
      nil
    end

    # Resources
    def _fetch_remote_rest_api_resources_for_rest_api(provider, rr)
      _client(provider).get_resources({
                                        rest_api_id: rr._terraform_id
                                      })['items'].map(&:to_h).map do |res|
        next unless res[:path_part] # default resource has no path_part
        res[:_terraform_id] = res[:id]
        res[:_geo_id]       = "#{rr._geo_id}::#{res[:path_part]}"
        res
      end
    end

    def _fetch_remote_rest_api_resources(provider)
      _fetch_remote_rest_apis(provider).map do |rr|
        _fetch_remote_rest_api_resources_for_rest_api(provider, rr)
      end.flatten.compact
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
      _remote_rest_and_resource(provider) do |rr, res|
        (res.resource_methods || {}).keys.map do |meth|
          yield rr, res, meth
        end
      end
    end

    # Integration
    def _fetch_integration(rr, res, meth)
      return _client(provider).get_integration({
                                                 rest_api_id: rr._terraform_id,
                                                 resource_id: res._terraform_id,
                                                 http_method: meth
                                               }).to_h
    rescue Aws::APIGateway::Errors::NotFoundException
      return nil
    end

    # Method
    def _fetch_method(rr, res, meth)
      return _client(provider).get_method({
                                            rest_api_id: rr._terraform_id,
                                            resource_id: res._terraform_id,
                                            http_method: meth
                                          }).to_h
    rescue Aws::APIGateway::Errors::NotFoundException
      return nil
    end
  end
end
