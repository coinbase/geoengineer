########################################################################
# AwsRouteTableAssociation is the +aws_route_table_association+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/route_table_association.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsRouteTableAssociation < GeoEngineer::Resource
  validate -> { validate_required_attributes([:subnet_id, :route_table_id]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{subnet_id}::#{route_table_id}" } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources
    AwsClients
      .ec2
      .describe_route_tables['route_tables']
      .map(&:to_h)
      .map { |route_table| route_table[:associations] }
      .flatten
      .compact
      .map do |association|
        association.merge(
          {
            _terraform_id: association[:route_table_association_id],
            _geo_id: "#{association[:subnet_id]}::#{association[:route_table_id]}"
          }
        )
      end
  end
end
