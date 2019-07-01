########################################################################
# AwsPinpointApp is the +aws_pinpoint_app+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/pinpoint_app.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsPinpointApp < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients.pinpoint(provider).get_apps['applications_response'].item.map(&:to_h).map do |app|
      app.merge(
        {
          name: app[:name],
          _terraform_id: app[:id],
          _geo_id: app[:name]
        }
      )
    end
  end
end
