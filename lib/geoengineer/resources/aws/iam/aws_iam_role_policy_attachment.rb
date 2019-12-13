########################################################################
# AwsIamPolicyAttachment +aws_iam_role_policy_attachment+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_role_policy_attachment.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsIamRolePolicyAttachment < GeoEngineer::Resource
  validate -> { validate_required_attributes([:role]) }
  validate -> { validate_at_least_one_present([:_policy, :policy_arn]) }

  before :validation, -> { policy_arn _policy.to_ref(:arn) if _policy }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{role}:#{_policy&.name || policy_arn}" } }

  def support_tags?
    false
  end

  def find_remote_as_individual?
    true
  end

  def to_terraform_state
    tfstate = super

    attributes = {}
    attributes['policy_arn'] = determine_policy_arn
    attributes['role'] = role

    tfstate[:primary][:attributes] = attributes
    tfstate
  end

  # rubocop:disable Style/ClassVars
  def fetch_entities(policy_arn)
    @@role_cache ||= {}
    return @@role_cache[policy_arn] if @@role_cache.key?(policy_arn)

    roles = []

    response = AwsClients.iam(provider).list_entities_for_policy({ policy_arn: policy_arn })
    roles += response.policy_roles
    while response.next_page?
      response = response.next_page
      roles += response.policy_roles
    end

    @@role_cache[policy_arn] = roles
    roles
  rescue Aws::IAM::Errors::NoSuchEntity
    nil
  end

  def remote_resource_params
    arn = determine_policy_arn
    return {} unless arn

    attached_roles = fetch_entities(arn)
    return {} unless attached_roles
    build_remote_resource_params(arn, attached_roles)
  end

  def determine_policy_arn
    if policy_arn && !_policy
      # check if the policy ARN is likely a Terraform reference, if so we can't fetch it so return nil
      return /^\${[a-zA-Z0-9\._-]+}$/.match?(policy_arn) ? nil : policy_arn
    end

    return nil unless _policy
    return nil unless _policy.remote_resource

    _policy.remote_resource._terraform_id
  end

  def build_remote_resource_params(arn, entities)
    role_names = entities.map(&:role_name)
    return nil unless role_names.include?(self.role)

    {
      _terraform_id: "#{role}/#{arn}",
      _geo_id: "#{role}:#{_policy&.name || policy_arn}",
      policy_arn: arn
    }
  end
end
