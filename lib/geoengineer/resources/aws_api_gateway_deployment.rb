########################################################################
# AwsCloudTrail is the +api_gateway_deployment+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_deployment.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayDeployment < GeoEngineer::Resource
  validate -> {
    validate_required_attributes([
                                   :rest_api_id,
                                   :stage_name,
                                   :description
                                 ])
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { description } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients.api_gateway(provider).get_deployments['items'].map(&:to_h).map do |api|
      api[:_terraform_id] = api[:id]
      api[:_geo_id]       = api[:description]
      api
    end
  end
end
