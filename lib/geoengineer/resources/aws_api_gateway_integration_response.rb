########################################################################
# AwsCloudTrail is the +api_gatewat_rest_api+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_integration_response.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayIntegrationResponse < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> {
    validate_required_attributes([
                                   :rest_api_id,
                                   :resource_id,
                                   :http_method,
                                   :status_code
                                 ])
  }

  after :initialize, -> { self.rest_api_id = _rest_api.to_ref }
  after :initialize, -> { self.resource_id = _resource.to_ref }
  after :initialize, -> { depends_on [_rest_api, _resource].map(&:terraform_name) }

  after :initialize, -> { _geo_id -> { "#{_rest_api._geo_id}::#{_resource.geo_id}::#{http_method}::#{status_code}" } }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    _remote_rest_apis(provider).map do |rr|
      _remote_rest_resources(provider).map do |res|
        res.resource_methods.keys.map do |meth|
          api_integration = AwsClients.api_gateway(provider).get_integration({
                                                                               rest_api_id: rr._terraform_id,
                                                                               resource_id: res._terraform_id,
                                                                               http_method: meth
                                                                             }).to_h

          api_integration[:integration_responses].keys.map do |status_code|
            agir = {}
            agir[:_terraform_id] = "agir-#{rr._terraform_id}-#{res._terraform_id}-#{meth}-#{status_code}"
            agir[:_geo_id] = "#{rr._geo_id}::#{res._geo_id}::#{meth}::#{status_code}"
            agir
          end
        end
      end
    end.flatten.compact
  end
end
