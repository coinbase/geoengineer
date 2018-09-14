########################################################################
# AwsInstance is the +aws_db_parameter_group+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/db_parameter_group.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsInstance < GeoEngineer::Resource
  validate -> { validate_required_attributes([:ami, :instance_type]) }
  validate -> { validate_has_tag(:Name) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { NullObject.maybe(tags)[:Name] } }

  def self._all_remote_instances(provider)
    AwsClients.ec2.describe_instances.reservations.map(&:instances).flatten.map(&:to_h)
  end

  def self._fetch_remote_resources(provider)
    _all_remote_instances(provider).map do |instance|
      instance.merge(
        {
          _terraform_id: instance[:instance_id],
          _geo_id: instance[:tags]&.find { |tag| tag[:key] == "Name" }&.dig(:value)
        }
      )
    end
  end
end
