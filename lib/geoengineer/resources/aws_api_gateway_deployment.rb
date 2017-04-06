########################################################################
# AwsCloudTrail is the +api_gateway_deployment+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_deployment.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayDeployment < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> {
    validate_required_attributes([:rest_api_id, :stage_name])
  }

  after :initialize, -> { self.rest_api_id = _rest_api.to_ref }
  after :initialize, -> { _rest_api.api_resources[self.type][self.id] = self }

  after :initialize, -> { depends_on [_rest_api].map(&:terraform_name) }

  after :initialize, -> { _geo_id -> { "#{_rest_api._geo_id}::#{stage_name}" } }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      "rest_api_id" => _rest_api._terraform_id,
      "stage_name" => stage_name
    }
    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    _remote_rest_apis(provider).map do |rr|
      AwsClients.api_gateway(provider).get_deployments({ rest_api_id: rr._terraform_id })['items'].map(&:to_h).map do |deployment|
        stage_name = AwsClients.api_gateway(provider).get_stages({ rest_api_id: rr._terraform_id, deployment_id: deployment[:id] }).item.first&.stage_name
        next unless stage_name
        deployment[:_terraform_id] = deployment[:id]
        deployment[:_geo_id]       = "#{rr._geo_id}::#{stage_name}"
        deployment[:stage_name]    = stage_name
        deployment
      end
    end.flatten.compact
  end
end
