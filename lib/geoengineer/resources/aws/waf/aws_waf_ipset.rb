########################################################################
# AwsWafIpset is the +aws_waf_ipset+
# terraform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/waf_ipset.html"
########################################################################
class GeoEngineer::Resources::AwsWafIpset < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }
  validate :validate_correct_cidr_blocks

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def self._all_ip_set_ids(provider)
    options = { limit: 100 }
    has_more = true
    ipsets = []
    while has_more
      resp = AwsClients.waf(provider)
                       .list_ip_sets(options)

      ipsets += resp.ip_sets.map(&:ip_set_id)
      has_more = !resp.next_marker.nil? && !resp.ip_sets.empty?
      options[:next_marker] = resp.next_marker
    end
    ipsets
  end

  def self._all_ip_sets(provider, ids)
    ids.map do |id|
      AwsClients.waf(provider)
                .get_ip_set({ ip_set_id: id })
    end
  end

  def self._fetch_remote_resources(provider)
    ids = self._all_ip_set_ids(provider)
    ipsets = self._all_ip_sets(provider, ids)
    ipsets.map do |item|
      item.to_h.tap do |i|
        i[:_terraform_id] = item.ip_set.ip_set_id
        i[:_geo_id] = item.ip_set.name
      end
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
