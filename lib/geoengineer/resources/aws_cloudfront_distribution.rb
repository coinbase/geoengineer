########################################################################
# AwsCloudfrontDistribution is the +aws_cloudfront_distribution+
# terraform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/cloudfront_distribution.html}
########################################################################
class GeoEngineer::Resources::AwsCloudfrontDistribution < GeoEngineer::Resource
  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { comment } }
  after :initialize, -> { _arn -> { NullObject.maybe(remote_resource)._arn } }

  def self._fetch_remote_resources(provider)
    AwsClients.cloudfront(provider).list_distributions[:distribution_list][:items].map do |item|
      item.to_h.tap do |i|
        i[:_terraform_id] = item[:id]
        i[:_arn] = item[:arn]
        i[:_geo_id] = item[:comment]
      end
    end
  end

  def support_tags?
    true
  end
end
