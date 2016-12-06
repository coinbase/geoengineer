########################################################################
# AwsSubnet is the +aws_subnet+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/subnet.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsSubnet < GeoEngineer::Resource
  validate -> { validate_required_attributes([:cidr_block, :vpc_id]) }
  validate -> { validate_has_tag(:Name) }
  validate -> { validate_cidr_block(self.cidr_block) if self.cidr_block }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { NullObject.maybe(tags)[:Name] } }

  def self._fetch_remote_resources
    AwsClients.ec2.describe_subnets['subnets'].map(&:to_h).map do |subnet|
      subnet.merge(
        {
          _terraform_id: subnet[:subnet_id],
          _geo_id: subnet[:tags].find { |tag| tag[:key] == "Name" }[:value]
        }
      )
    end
  end
end
