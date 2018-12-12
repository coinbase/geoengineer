########################################################################
# AwsIamPolicyAttachment +aws_iam_role_policy_attachment+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_role_policy_attachment.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsIamRolePolicyAttachment < GeoEngineer::Resource
  validate -> { validate_required_attributes([:_policy, :role]) }

  before :validation, -> { policy_arn _policy.to_ref(:arn) if _policy }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{role}:#{_policy&.name}" } }

  @role_cache = {}

  def support_tags?
    false
  end

  def find_remote_as_individual?
    true
  end

  def to_terraform_state
    tfstate = super

    attributes = {}
    attributes['policy_arn'] = remote_resource.policy_arn if remote_resource
    attributes['role'] = role

    tfstate[:primary][:attributes] = attributes
    tfstate
  end

  def fetch_entities(policy_arn)
    return @role_cache[policy_arn] if self.class.role_cache.key?(policy_arn)

    roles = []

    response = AwsClients.iam(provider).list_entities_for_policy({ policy_arn: policy_arn })
    roles += response.policy_roles
    while response.next_page?
      response = response.next_page
      roles += response.policy_roles
    end

    @role_cache[policy_arn] = roles
  end

  def remote_resource_params
    return {} unless _policy
    return {} unless _policy.remote_resource

    arn = _policy.remote_resource._terraform_id
    attached_roles = fetch_entities(arn)

    build_remote_resource_params(arn, attached_roles)
  end

  def build_remote_resource_params(arn, entities)
    role_names = entities.map(&:role_name)
    return nil unless role_names.include?(self.role)

    {
      _terraform_id: "#{role}/#{arn}",
      _geo_id: "#{role}:#{_policy.name}",
      policy_arn: arn
    }
  end
end
