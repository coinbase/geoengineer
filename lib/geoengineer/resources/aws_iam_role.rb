require "uri"

########################################################################
# AwsIamGroup +aws_iam_role+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/iam_role.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsIamRole < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :assume_role_policy]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name.to_s } }

  def to_terraform_state
    tfstate = super

    arn = NullObject.maybe(remote_resource).arn
    assume_role_policy = NullObject.maybe(remote_resource).assume_role_policy

    attributes = {}
    attributes['arn'] = arn if arn
    attributes['assume_role_policy'] = _normalize_json(assume_role_policy) if assume_role_policy

    tfstate[:primary][:attributes] = attributes
    tfstate
  end

  def _assume_role_policy_file(path, binding_obj = nil)
    _json_file(:assume_role_policy, path, binding_obj)
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources
    roles = AwsClients.iam.list_roles['roles'].map(&:to_h)
    roles.map do |r|
      r.merge({ name: r[:role_name],
                _geo_id: r[:role_name],
                _terraform_id: r[:role_name],
                assume_role_policy: URI.decode(r[:assume_role_policy_document]) })
    end
  end
end
