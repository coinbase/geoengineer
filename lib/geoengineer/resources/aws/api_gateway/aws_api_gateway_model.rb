require_relative "./helpers"

########################################################################
# AwsApiGatewayModel is the +api_gateway_model+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_model.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayModel < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> { validate_required_attributes([:rest_api_id, :name, :content_type, :schema]) }

  after :initialize, -> { self.rest_api_id = _rest_api.to_ref }
  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{_rest_api._geo_id}::#{name}" } }

  def support_tags?
    false
  end

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'name' => name,
      'rest_api_id' => rest_api_id
    }
    tfstate
  end

  def self._fetch_remote_resources(provider)
    _remote_rest_api_models(provider) { |_, model| model }.flatten.compact
  end
end
