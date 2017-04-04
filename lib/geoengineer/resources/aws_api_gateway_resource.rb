########################################################################
# AwsCloudTrail is the +api_gatewat_rest_api+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_resource.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayResource < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  # The Rest API resource object and the parent resource object must be passed
  validate -> { validate_required_attributes([:rest_api_id, :parent_id, :path_part]) }

  # Must pass the rest_api as _rest_api resource for additional information
  validate -> { validate_required_attributes([:_rest_api]) }

  before :validation, -> { self.rest_api_id = _rest_api&.to_ref }
  # Parent is a resource (the default being the root resource of the rest_api '/')
  # At the moment we only support rest_api being the root resource
  before :validation, -> { self.parent_id = _rest_api.to_ref("root_resource_id") }

  after :initialize, -> { _geo_id -> { "#{_rest_api._geo_id}::#{path_part}" } }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _id -> { _terraform_id } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    _remote_rest_apis(provider).map do |rr|
      AwsClients.api_gateway(provider).get_resources({ rest_api_id: rr._terraform_id })['items'].map(&:to_h).map do |res|
        next unless res[:path_part] # default resource has no path_part
        res[:_terraform_id] = res[:id]
        res[:_geo_id]       = "#{rr._geo_id}::#{res[:path_part]}"
        res
      end
    end.flatten.compact
  end
end
