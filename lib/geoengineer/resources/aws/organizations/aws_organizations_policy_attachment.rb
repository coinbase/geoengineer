########################################################################
# AwsOrganizationsPolicyAttachment is the +aws_organizations_policy_attachment+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/organizations_policy_attachment.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsOrganizationsPolicyAttachment < GeoEngineer::Resource
  validate -> { validate_required_attributes([:policy_id, :target_id]) }

  after :initialize, -> { _terraform_id -> { "#{target_id}:#{policy_id}" } }
  after :initialize, -> { _geo_id -> { "#{target_id}:#{policy_id}" } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients
      .organizations(provider)
      .list_policies({ filter: "SERVICE_CONTROL_POLICY" })
      .policies
      .map(&:to_h)
      .map { |pol| _generate_attachments(provider, pol) }
      .flatten
  end

  def self._generate_attachments(provider, policy)
    targets =
      AwsClients
      .organizations(provider)
      .list_targets_for_policy({ policy_id: policy[:id] })
      .targets
      .map(&:to_h)

    targets.map do |target|
      {
        _terraform_id: "#{target[:target_id]}:#{policy[:id]}",
        _geo_id: "#{target[:target_id]}:#{policy[:id]}",
        policy_id: policy[:id],
        target_id: target[:target_id]
      }
    end
  end
end
