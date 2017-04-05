########################################################################
# AwsCloudTrail is the +api_gatewat_rest_api+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_method.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayMethod < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> {
    validate_required_attributes([
                                   :rest_api_id,
                                   :resource_id,
                                   :http_method,
                                   :authorization
                                 ])
  }

  # Must pass the rest_api as _rest_api resource for additional information
  after :initialize, -> { self.rest_api_id = _rest_api.to_ref }
  after :initialize, -> { _rest_api.api_resources[self.type][self.id] = self }

  after :initialize, -> { self.resource_id = _resource.to_ref }
  after :initialize, -> { depends_on [_rest_api, _resource].map(&:terraform_name) }

  after :initialize, -> { _geo_id -> { "#{_rest_api._geo_id}::#{_resource._geo_id}::#{http_method}" } }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      "rest_api_id" => _rest_api._terraform_id,
      "resource_id" => _resource._terraform_id,
      "http_method" => http_method,
      "authorization" => authorization
    }
    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    _remote_rest_apis(provider).map do |rr|
      _remote_rest_resources(provider).map do |res|
        res.resource_methods.keys.map do |meth|
          api_method = AwsClients.api_gateway(provider).get_method({
                                                                     rest_api_id: rr._terraform_id,
                                                                     resource_id: res._terraform_id,
                                                                     http_method: meth
                                                                   }).to_h

          api_method[:_terraform_id] = "agm-#{rr._terraform_id}-#{res._terraform_id}-#{meth}"
          api_method[:_geo_id] = "#{rr._geo_id}::#{res._geo_id}::#{meth}"
          api_method
        end
      end
    end.flatten.compact
  end
end
