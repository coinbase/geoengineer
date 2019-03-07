require_relative "./helpers"

##########################################################################################
# AwsApiGatewayGatewayResponse is the +api_gateway_request_validator+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_gateway_response.html}
##########################################################################################
class GeoEngineer::Resources::AwsApiGatewayGatewayResponse < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> { validate_required_attributes([:rest_api_id, :response_type]) }

  after :initialize, -> { self.rest_api_id = _rest_api.to_ref }
  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{_rest_api._geo_id}::#{response_type}" } }

  def support_tags?
    false
  end

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'response_type' => response_type,
      'rest_api_id'   => _rest_api._terraform_id
    }
    tfstate
  end

  def self._fetch_remote_resources(provider)
    _remote_rest_api_gateway_responses(provider) { |_, gr| gr }.flatten.compact
  end
end
