########################################################################
# AwsCloudHsm is the +aws_cloudhsm_v2_cluster+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/cloudhsm_v2_cluster.html}
########################################################################
class GeoEngineer::Resources::AwsCloudhsmV2Hsm < GeoEngineer::Resource
  validate -> { validate_required_attributes([:cluster_id]) }
  validate -> { validate_has_tag(:Name) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { 'testing123' } }

  def self._fetch_remote_resources(provider)
    client = AwsClients.cloudhsm(provider)
    client.describe_clusters[:clusters]
          .map(&:to_h).map do |hsm|
      hsm.merge(
        {
          _terraform_id: hsm[:hsm_id],
          _geo_id: 'testing123'
        }
      )
      end
  end
end
