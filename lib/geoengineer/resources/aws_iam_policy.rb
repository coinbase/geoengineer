########################################################################
# AwsIamPolicy +aws_iam_policy+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_policy.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsIamPolicy < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :policy]) }

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

  def _policy(path)
    _json_file(:policy, path)
  end

  def _get_policy_document(arn, version_id)
    response = AwsClients.iam.get_policy_version({ policy_arn: arn,
                                                   version_id: version_id })
    URI.decode(response.policy_version.document)
  end

  def self._all_remote_policies
    AwsClients.iam.list_policies({ scope: "Local" }).each.map(&:policies).flatten.map(&:to_h)
  end

  def self._fetch_remote_resources
    _all_remote_policies.map(&:to_h).map do |policy|
      {
        '_terraform_id' => policy[:arn],
        '_geo_id' => policy[:policy_name],
        'arn' => policy[:arn],
        'default_version_id' => policy[:default_version_id],
        'name' => policy[:policy_name]
      }
    end
  end
end
