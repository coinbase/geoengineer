########################################################################
# AwsCloudHsm is the +aws_cloudhsm_v2_cluster+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/cloudhsm_v2_cluster.html}
########################################################################
class GeoEngineer::Resources::AwsCloudhsmV2Hsm < GeoEngineer::Resource
  validate -> { validate_required_attributes([:cluster_id, :subnet_id]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{cluster_id}_#{subnet_id}" } }

  def self._fetch_remote_resources(provider)
    client = AwsClients.cloudhsm(provider)
    flattened_hsms = []
    client.describe_clusters[:clusters]
          .map(&:to_h).map do |hsm_cluster|
      hsm_cluster[:hsms].map(&:to_h).map do |hsm|
        flattened_hsms << hsm.merge(
          {
            _terraform_id: hsm[:hsm_id],
            _geo_id: "#{hsm[:cluster_id]}_#{hsm[:subnet_id]}"
          }
        )
      end
    end
    flattened_hsms
  end

  def support_tags?
    false
  end
end
