require_relative "./api_gateway/helpers"

########################################################################
# AwsCloudTrail is the +api_gatewat_rest_api+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_method_response.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayMethodResponse < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> {
    validate_required_attributes([
                                   :rest_api_id,
                                   :resource_id,
                                   :http_method,
                                   :status_code
                                 ])
  }

  # Must pass the rest_api as _rest_api resource for additional information
  after :initialize, -> { self.rest_api_id = _rest_api.to_ref }
  after :initialize, -> { _rest_api.api_resources[self.type][self.id] = self }

  after :initialize, -> { self.resource_id = _resource.to_ref }
  after :initialize, -> { depends_on [_rest_api, _resource].map(&:terraform_name) }

  after :initialize, -> {
    _geo_id -> {
              [
                _rest_api._geo_id,
                _resource._geo_id,
                http_method,
                status_code
              ].join("::")
            }
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      "rest_api_id" => _rest_api._terraform_id,
      "resource_id" => _resource._terraform_id,
      "http_method" => http_method,
      "status_code" => status_code
    }
    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    _remote_rest_api_resource_method(provider) do |rr, res, meth|
      api_method = self._fetch_method(provider, rr, res, meth)
      next nil if api_method.nil?

      (api_method[:method_responses] || {}).keys.map do |status_code|
        agmr = {}
        tf_id = "agmr-#{rr[:_terraform_id]}-#{res[:_terraform_id]}-#{meth}-#{status_code}"
        agmr[:_terraform_id] = tf_id
        agmr[:_geo_id] = "#{rr[:_geo_id]}::#{res[:_geo_id]}::#{meth}::#{status_code}"
        agmr
      end
    end.flatten.compact
  end
end
