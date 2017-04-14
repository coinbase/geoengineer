require_relative "./api_gateway/helpers"

########################################################################
# AwsCloudTrail is the +api_gatewat_rest_api+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_usage_plan.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayUsagePlan < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> { validate_required_attributes([:name, :description]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients.api_gateway(provider).get_usage_plans['items'].map(&:to_h).map do |api|
      api[:_terraform_id]    = api[:id]
      api[:_geo_id]          = api[:name]
      api
    end
  end
end
