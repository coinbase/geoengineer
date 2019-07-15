########################################################################
# AwsAlbTargetGroupAttachment is the +aws_alb_target_group_attachment+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_alb_target_group_attachment.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsAlbTargetGroupAttachment < GeoEngineer::Resource
  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  validate -> { validate_required_attributes([:target_group_arn, :target_id]) }

  before :validation, -> { target_group_arn _target_group.to_ref(:arn) if _target_group }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id       -> { "#{target_group_arn}:#{target_id}" } }

  def support_tags?
    false
  end

  def find_remote_as_individual?
    true
  end

  def to_terraform_state
    tfstate = super

    attributes = {}
    attributes['target_group_arn'] = remote_resource.target_group_arn if remote_resource
    attributes['target_id'] = target_id

    tfstate[:primary][:attributes] = attributes
    tfstate
  end

  def remote_resource_params
    return {} unless target_id
    return {} unless _target_group.remote_resource

    arn = _target_group.remote_resource.target_group_arn

    descriptions = AwsClients
                   .alb(provider)
                   .describe_target_health({ target_group_arn: arn })
                   .target_health_descriptions
                   .map(&:to_h)

    build_remote_resource_params(arn, descriptions)
  end

  def build_remote_resource_params(arn, descriptions)
    target = descriptions.find do |description|
      description.dig(:target, :id) == target_id
    end

    return {} unless target

    response = {
      _terraform_id: "#{arn}/#{target_id}",
      _geo_id: "#{arn}:#{target_id}",
      target_group_arn: arn,
      target_id: target_id
    }

    response
  end
end
