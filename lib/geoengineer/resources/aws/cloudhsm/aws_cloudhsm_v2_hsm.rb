########################################################################
# AwsCloudHsm is the +aws_cloudhsm_v2_hsm+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/cloudhsm_v2_hsm.html}
########################################################################
class GeoEngineer::Resources::AwsCloudhsmV2Hsm < GeoEngineer::Resource
  validate -> { validate_required_attributes([:subnet_id]) }
  validate -> { validate_at_least_one_present([:_cluster, :cluster_id]) }

  after :initialize, -> { cluster_id -> { self._cluster.to_ref(:id) if self._cluster } }
  after :initialize, -> { _cluster_name -> { self._cluster.tags[:Name] if self._cluster } }
  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{self._cluster_name || self.cluster_id}_#{self.subnet_id}" } }

  def self._fetch_remote_resources(provider)
    client = AwsClients.cloudhsm(provider)
    client
      .describe_clusters
      .clusters
      .map { |cluster| _extract_hsms(cluster, provider) }
      .flatten
  end

  def self._extract_hsms(cluster, provider)
    cluster.hsms.map do |hsm|
      hsm.to_h.merge(
        {
          _terraform_id: hsm[:hsm_id],
          _geo_id: _construct_geo_id(hsm, provider)
        }
      )
    end
  end

  def self._construct_geo_id(hsm, provider)
    cluster_name = _cluster_name(hsm[:cluster_id], provider) || hsm[:cluster_id]

    "#{cluster_name}_#{hsm[:subnet_id]}"
  end

  def self._cluster_name(cluster_id, provider)
    AwsClients
      .cloudhsm(provider)
      .list_tags({ resource_id: cluster_id })
      .tag_list
      .find { |tag| tag[:key] == "Name" }
      &.dig(:value)
  end

  def support_tags?
    false
  end
end
