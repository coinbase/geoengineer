########################################################################
# AwsCodedeployDeploymentGroup is the +aws_codedeploy_deployment_group+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/codedeploy_deployment_group.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsCodedeployDeploymentGroup < GeoEngineer::Resource
  validate -> {
    validate_required_attributes([
                                   :app_name, :deployment_group_name, :service_role_arn
                                 ])
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id       -> { self[:deployment_group_name] } }

  def support_tags?
    false
  end

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'app_name' => app_name,
      'deployment_group_name' => deployment_group_name
    }
    tfstate
  end

  def self._fetch_remote_resources(provider)
    client = AwsClients.codedeploy(provider)
    apps = client.list_applications.applications
    return [] if apps.empty?
    apps.map do |app|
      _fetch_groups(client, app)
    end.flatten
  end

  def self._fetch_groups(client, app)
    groups = client.list_deployment_groups({ application_name: app }).deployment_groups
    return [] if groups.empty?
    client.batch_get_deployment_groups({
                                         application_name: app,
                                         deployment_group_names: groups
                                       }).deployment_groups_info.map(&:to_h).map do |group|
      group.merge(
        {
          _terraform_id: group[:deployment_group_id],
          _geo_id:       group[:deployment_group_name]
        }
      )
    end
  end
end
