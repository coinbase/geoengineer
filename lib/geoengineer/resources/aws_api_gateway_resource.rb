########################################################################
# AwsCloudTrail is the +api_gatewat_rest_api+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_resource.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayResource < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  # The Rest API resource object and the parent resource object must be passed
  validate -> { validate_required_attributes([:rest_api_id, :parent_id, :path_part]) }

  after :initialize, -> { self.rest_api_id = _rest_api.to_ref }
  after :initialize, -> { _rest_api.api_resources[self.type][self.id] = self }

  # Parent is a resource (the default being the root resource of the rest_api '/')
  # At the moment we only support rest_api being the root resource
  after :initialize, -> { self.parent_id = _rest_api.to_ref("root_resource_id") }

  after :initialize, -> { depends_on [_rest_api.terraform_name] }

  after :initialize, -> { _geo_id -> { "#{_rest_api._geo_id}::#{path_part}" } }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _id -> { _terraform_id } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      "rest_api_id" => _rest_api._terraform_id
    }
    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    _fetch_remote_rest_api_resources(provider)
  end
end
