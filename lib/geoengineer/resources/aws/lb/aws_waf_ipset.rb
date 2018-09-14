########################################################################
# AwsWafIpset is the +aws_waf_ipset+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/waf_ipset.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsWafIpset < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }
  validate :validate_correct_cidr_blocks

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def self._fetch_remote_resources(provider)
    AwsClients.waf(provider).list_ip_sets['ip_sets'].map(&:to_h).map do |s|
      s.merge(
        {
          _terraform_id: s[:ip_set_id],
          _geo_id: s[:name]
        }
      )
      s
    end
  end

  def validate_correct_cidr_blocks
    errors = []
    error = validate_cidr_block(self.ip_set_descriptors&.value)
    errors << error unless error.nil?
    errors
  end

  def support_tags?
    false
  end
end
