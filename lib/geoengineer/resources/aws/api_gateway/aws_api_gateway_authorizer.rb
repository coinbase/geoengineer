require_relative "./helpers"

########################################################################
# AwsCloudTrail is the +aws_api_gateway_authorizer+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_api_gateway_authorizer.html}
########################################################################
# TODO: not fully implemented
class GeoEngineer::Resources::AwsApiGatewayAuthorizer < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> { validate_required_attributes([:name, :rest_api_id]) }

  after :initialize, -> { self.rest_api_id = _rest_api.to_ref }
  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def support_tags?
    false
  end

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] =
    if authorizer_uri
      {
        'name' => name,
        'rest_api_id' => _rest_api._terraform_id
      }
    else
      {
        'name' => name,
        'rest_api_id' => _rest_api._terraform_id,
        'auhtorizer_uri' => authorizer_uri,
      }
    end

    tfstate
  end

  def self._fetch_remote_resources(provider)
    _remote_rest_api_gateway_authorizers(provider) { |_, rv| rv }.flatten.compact
  end
end
