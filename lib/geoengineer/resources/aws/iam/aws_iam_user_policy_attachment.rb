########################################################################
# AwsIamPolicyAttachment +aws_iam_user_policy_attachment+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_user_policy_attachment.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsIamUserPolicyAttachment < GeoEngineer::Resource
  validate -> { validate_required_attributes([:_policy, :user]) }

  before :validation, -> { policy_arn _policy.to_ref(:arn) if _policy }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{user}:#{_policy&.name}" } }

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
    attributes['user'] = user

    tfstate[:primary][:attributes] = attributes
    tfstate
  end

  # rubocop:disable Style/ClassVars
  def fetch_entities(policy_arn)
    @@user_cache ||= {}
    return @@user_cache[policy_arn] if @@user_cache.key?(policy_arn)

    users = []

    response = AwsClients.iam(provider).list_entities_for_policy({ policy_arn: policy_arn })
    users += response.policy_users
    while response.next_page?
      response = response.next_page
      users += response.policy_users
    end

    @@user_cache[policy_arn] = users
    users
  end

  def remote_resource_params
    return {} unless _policy
    return {} unless _policy.remote_resource

    arn = _policy.remote_resource._terraform_id
    attached_users = fetch_entities(arn)

    build_remote_resource_params(arn, attached_users)
  end

  def build_remote_resource_params(arn, entities)
    user_names = entities.map(&:user_name)
    return nil unless user_names.include?(self.user)

    {
      _terraform_id: "#{user}/#{arn}",
      _geo_id: "#{user}:#{_policy.name}",
      policy_arn: arn
    }
  end
end
