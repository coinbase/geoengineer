########################################################################
# AwsIamPolicy +aws_iam_policy+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_policy.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsIamPolicy < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :policy]) }
  validate -> { validate_policy_length(self.policy, 10_240) }
  validate -> { validate_resources_not_empty(self.policy) }

  after :initialize, -> {
    _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id }
  }
  after :initialize, -> {
    _geo_id -> { name.to_s }
  }

  def to_terraform_state
    arn = NullObject.maybe(remote_resource).arn
    default_version_id = NullObject.maybe(remote_resource).default_version_id

    policy = _get_policy_document(arn, default_version_id)

    tfstate = super

    attributes = { 'policy' => policy }
    attributes['arn'] = arn if arn

    tfstate[:primary][:attributes] = attributes

    tfstate
  end

  def support_tags?
    false
  end

  # Validates that the policy has at least one statement
  def validate_resources_not_empty(policy)
    return unless policy
    json_policy = JSON.parse(policy)
    lower_policy = json_policy.transform_keys(&:downcase)
    statements = lower_policy["statement"] \
      || lower_policy[:statement] \
      || []
    return unless statements.any? { |statement| missing_resources?(statement) }
    "Policy #{name} has a statement that has a Resource or NotResource directive that is empty"
  end

  def missing_resources?(statement)
    lower_statement = statement.transform_keys(&:downcase)
    resource = lower_statement["resource"] \
      || lower_statement[:resource] \
      || lower_statement["notresource"] \
      || lower_statement[:notresource] \
      || []
    resource.empty?
  end

  def _policy_file(path, binding_obj = nil)
    _json_file(:policy, path, binding_obj)
  end

  def _get_policy_document(arn, version_id)
    response = AwsClients.iam.get_policy_version({ policy_arn: arn,
                                                   version_id: version_id })
    URI.decode(response.policy_version.document)
  end

  def self._all_remote_policies(provider)
    AwsClients.iam(provider)
              .list_policies({ scope: "Local" })
              .each.map(&:policies).flatten.map(&:to_h)
  end

  def self._fetch_remote_resources(provider)
    _all_remote_policies(provider).map(&:to_h).map do |policy|
      {
        _terraform_id: policy[:arn],
        _geo_id: policy[:policy_name],
        arn: policy[:arn],
        default_version_id: policy[:default_version_id],
        name: policy[:policy_name]
      }
    end
  end
end
