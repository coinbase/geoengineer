########################################################################
# AwsRouteTableAssociation is the +aws_route_table_association+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/route_table_association.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsRouteTableAssociation < GeoEngineer::Resource
  validate -> { validate_required_attributes([:subnet_id, :route_table_id]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{subnet_id}::#{route_table_id}" } }

  def subnet(sn)
    self.subnet_id = sn._terraform_id || sn.to_ref
  end


  def route_table(rt)
    self.route_table_id = rt._terraform_id || rt.to_ref
  end

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'subnet_id' => subnet_id,
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
      .map { |route_table| route_table[:associations] }
      .flatten
      .compact
      .reject { |association| association[:main] }
      .map { |association| _merge_ids(association) }
  end

  def self._merge_ids(association)
    association.merge(
      {
        _terraform_id: association[:route_table_association_id],
        _geo_id: "#{association[:subnet_id]}::#{association[:route_table_id]}"
      }
    )
  end
end
