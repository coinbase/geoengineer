########################################################################
# AwsRouteTable is the +aws_route_table+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/route_table.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsRouteTable < GeoEngineer::Resource
  validate -> { validate_required_attributes([:vpc_id]) }
  validate -> { validate_has_tag(:Name) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { NullObject.maybe(tags)[:Name] } }

  def self._fetch_remote_resources
    AwsClients.ec2.describe_route_tables['route_tables'].map(&:to_h).map do |route_table|
      route_table.merge(
        {
          _terraform_id: route_table[:route_table_id],
          _geo_id: route_table[:tags].find { |tag| tag[:key] == "Name" }[:value]
        }
      )
    end
  end
end
