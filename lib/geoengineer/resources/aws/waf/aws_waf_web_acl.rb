########################################################################
# AwsWafWebACL is the +aws_waf_web_acl+
# terraform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/waf_web_acl.html}
########################################################################
class GeoEngineer::Resources::AwsWafWebAcl < GeoEngineer::Resource
  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def self._all_web_acl_ids(provider)
    options = { limit: 100 }
    has_more = true
    web_acls = []
    while has_more
      resp = AwsClients.waf(provider)
                       .list_web_acls(options)

      web_acls += resp.web_acls.map(&:web_acl_id)
      has_more = !resp.next_marker.nil? && !resp.web_acls.empty?
      options[:next_marker] = resp.next_marker
    end
    web_acls
  end

  def self._all_web_acls(provider, ids)
    ids.map do |id|
      AwsClients.waf(provider)
                .get_web_acl({ web_acl_id: id })
    end
  end

  def self._fetch_remote_resources(provider)
    ids = self._all_web_acl_ids(provider)
    web_acls = self._all_web_acls(provider, ids)
    web_acls.map do |item|
      item.to_h.tap do |i|
        i[:_terraform_id] = item.web_acl.web_acl_id
        i[:_geo_id] = item.web_acl.name
      end
    end
  end

  def support_tags?
    false
  end
end
