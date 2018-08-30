########################################################################
# AwsCodedeployDeploymentConfig is the +aws_codedeploy_deployment_config+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/codedeploy_deployment_config.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsCodedeployDeploymentConfig < GeoEngineer::Resource
  validate -> { validate_required_attributes([:deployment_config_name]) }

  after :initialize, -> { _terraform_id -> { self[:deployment_config_name] } }
  after :initialize, -> { _geo_id       -> { self[:deployment_config_name] } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients
      .codedeploy(provider)
      .list_deployment_configs.deployment_configs_list.map do |deployment_config|
      {
        _terraform_id: deployment_config,
        _geo_id: deployment_config
      }
    end
  end
end
