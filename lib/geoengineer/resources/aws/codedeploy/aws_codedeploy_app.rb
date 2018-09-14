########################################################################
# AwsCodedeployApp is the +aws_codedeploy_app+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/codedeploy_app.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsCodedeployApp < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id       -> { self[:name] } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    client = AwsClients.codedeploy(provider)
    apps = client.list_applications.applications
    return [] if apps.empty?
    client.batch_get_applications({
                                    application_names: apps
                                  }).applications_info.map(&:to_h).map do |app|
      app.merge(
        {
          _terraform_id: "#{app[:application_id]}:#{app[:application_name]}",
          _geo_id:       app[:application_name]
        }
      )
    end
  end
end
