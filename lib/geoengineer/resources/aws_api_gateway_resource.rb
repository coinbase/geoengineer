########################################################################
# AwsCloudTrail is the +api_gatewat_rest_api+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_resource.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayResource < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  # The Rest API resource object and the parent resource object must be passed
  validate -> { validate_required_attributes([:_rest_api, :_parent]) }
  validate -> { validate_required_attributes([:rest_api_id, :parent_id, :path_part]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{_rest_api.name}::#{_parent.}" } }

  # If the parent is a rest_api then it it the root_resource_id
  # Otherwise it is just the resource_id
  before :validate, -> {  }

  # assign the rest_api id
  before :validate, -> { rest_api_id = _rest_api._id }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    _remote_rest_apis.map do |rr|
        AwsClients.api_gateway(provider)
          .get_resources({ rest_api_id: rr.id })['items']
          .map(&:to_h).map do |api|
            api[:_terraform_id] = api[:id]
            api[:_geo_id]       = "#{rr.name}::#{rr.parent_id}::#{api[:path_part]}"
            api
        end
    end.flatten
  end
end
