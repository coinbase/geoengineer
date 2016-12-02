########################################################################
# AwsIamGroup +aws_iam_group+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_group.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsIamGroup < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name.to_s } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources
    groups = AwsClients.iam.list_groups['groups'].map(&:to_h)

    groups.map do |g|
      g[:name] = g[:group_name]
      g[:_geo_id] = g[:group_name]
      g[:_terraform_id] = g[:group_name]
      g
    end
  end
end
