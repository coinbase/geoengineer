########################################################################
# AwsVpc is the +aws_vpc+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/vpc.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsVpc < GeoEngineer::Resource
  validate -> { validate_required_attributes([:cidr_block]) }
  validate -> { validate_has_tag(:Name) }
  validate -> { validate_cidr_block(self.cidr_block) if self.cidr_block }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { NullObject.maybe(tags)[:Name] } }

  def self._fetch_remote_resources
    AwsClients.ec2.describe_vpcs['vpcs'].map(&:to_h).map do |vpc|
      vpc.merge(
        {
          _terraform_id: vpc[:vpc_id],
          _geo_id: vpc[:tags].find { |tag| tag[:key] == "Name" }&.dig(:value)
        }
      )
    end
  end
end
