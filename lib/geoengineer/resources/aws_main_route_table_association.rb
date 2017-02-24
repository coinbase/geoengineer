########################################################################
# AwsMainRouteTableAssociation is the +aws_main_route_table_association+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/main_route_table_assoc.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsMainRouteTableAssociation < GeoEngineer::Resource
  validate -> { validate_required_attributes([:vpc_id, :route_table_id]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{vpc_id}::#{route_table_id}" } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'vpc_id' => vpc_id,
      'route_table_id' => route_table_id
    }
    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients
      .ec2(provider)
      .describe_route_tables['route_tables']
      .map(&:to_h)
      .select { |route_table| route_table[:associations] }
      .map { |route_table| _extract_associations(route_table) }
      .flatten
      .select { |association| association[:main] }
      .map { |association| _merge_ids(association) }
  end

  def self._merge_ids(association)
    association.merge(
      {
        _terraform_id: association[:route_table_association_id],
        _geo_id: "#{association[:vpc_id]}::#{association[:route_table_id]}"
      }
    )
  end

  def self._extract_associations(route_table)
    route_table[:associations].map do |association|
      association.merge({ vpc_id: route_table[:vpc_id] })
    end
  end
end
