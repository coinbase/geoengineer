########################################################################
# AwsNetworkAcl is the +aws_network_acl+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/network_acl.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsNetworkAcl < GeoEngineer::Resource
  validate -> { validate_required_attributes([:vpc_id]) }
  validate -> { validate_has_tag(:Name) }
  validate -> {
    unless self.all_egress.empty?
      validate_subresource_required_attributes(
        :egress,
        [:from_port, :to_port, :rule_no, :action, :protocol]
      )
    end

    unless self.all_ingress.empty?
      validate_subresource_required_attributes(
        :ingress,
        [:from_port, :to_port, :rule_no, :action, :protocol]
      )
    end
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { NullObject.maybe(tags)[:Name] } }

  def self._fetch_remote_resources
    AwsClients.ec2.describe_network_acls['network_acls'].map(&:to_h).map do |network_acl|
      network_acl.merge(
        {
          _terraform_id: network_acl[:network_acl_id],
          _geo_id: network_acl[:tags]&.find { |tag| tag[:key] == "Name" }&.dig(:value)
        }
      )
    end
  end
end
