########################################################################
# AwsIamInstanceProfile +aws_iam_instance_profile+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_instance_profile.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsIamInstanceProfile < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :roles]) }

  before :validation, -> { policy_arn _policy.to_ref(:arn) if _policy }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name.to_s } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    profiles = AwsClients.iam(provider).list_instance_profiles['instance_profiles'].map(&:to_h)
    profiles.map do |p|
      {
        name: p[:instance_profile_name],
        _geo_id: p[:instance_profile_name],
        _terraform_id: p[:instance_profile_name]
      }
    end
  end
end
