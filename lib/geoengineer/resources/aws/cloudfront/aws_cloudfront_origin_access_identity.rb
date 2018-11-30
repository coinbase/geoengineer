########################################################################
# AwsCloudfrontOriginAccessIdentity is the +aws_cloudfront_origin_access_identity+
# terraform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/cloudfront_origin_access_identity.html}
########################################################################
class GeoEngineer::Resources::AwsCloudfrontOriginAccessIdentity < GeoEngineer::Resource
  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { comment } }

  def self._all_access_identities(provider)
    options = { max_items: 100 }
    has_more = true
    access_identities = []
    while has_more
      resp = AwsClients.cloudfront(provider)
                       .list_cloud_front_origin_access_identities(options)

      access_identities += resp.cloud_front_origin_access_identity_list.items
      has_more = !resp.cloud_front_origin_access_identity_list.next_marker.nil? &&
                 !resp.cloud_front_origin_access_identity_list.items.empty?
      options[:marker] = resp.cloud_front_origin_access_identity_list.next_marker
    end
    access_identities
  end

  def self._fetch_remote_resources(provider)
    self._all_access_identities(provider).map do |item|
      item.to_h.tap do |i|
        i[:_terraform_id] = item[:id]
        i[:_geo_id] = item[:comment]
      end
    end
  end

  def support_tags?
    false
  end
end
