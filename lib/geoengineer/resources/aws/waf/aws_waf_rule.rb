########################################################################
# AwsWafRule is the +aws_waf_rule+
# terraform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/waf_rule.html}
########################################################################
class GeoEngineer::Resources::AwsWafRule < GeoEngineer::Resource
  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def self._all_rule_ids(provider)
    options = { limit: 100 }
    has_more = true
    web_acls = []
    while has_more
      resp = AwsClients.waf(provider)
                       .list_rules(options)

      web_acls += resp.rules.map(&:rule_id)
      has_more = !resp.next_marker.nil? && !resp.rules.empty?
      options[:next_marker] = resp.next_marker
    end
    web_acls
  end

  def self._all_rules(provider, ids)
    ids.map do |id|
      AwsClients.waf(provider)
                .get_rule({ rule_id: id })
    end
  end

  def self._fetch_remote_resources(provider)
    ids = self._all_rule_ids(provider)
    rules = self._all_rules(provider, ids)
    rules.map do |item|
      item.to_h.tap do |i|
        i[:_terraform_id] = item.rule.rule_id
        i[:_geo_id] = item.rule.name
      end
    end
  end

  def support_tags?
    false
  end
end
