########################################################################
# AwsCloudHsm is the +aws_cloudhsm_v2_cluster+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/cloudhsm_v2_cluster.html}
########################################################################
class GeoEngineer::Resources::AwsCloudhsmV2Cluster < GeoEngineer::Resource
  validate -> { validate_required_attributes([:hsm_type, :subnet_ids]) }
  validate -> { validate_has_tag(:Name) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { NullObject.maybe(tags)[:Name] } }

  def to_terraform_state
    tfstate = super

    attributes = {}
    attributes['tags.%'] = tags.attributes.keys.count.to_s
    tags.attributes.each do |(key, value)|
      attributes["tags.#{key}"] = value.to_s
    end

    tfstate[:primary][:attributes] = attributes
    tfstate
  end

  def self._fetch_remote_resources(provider)
    client = AwsClients.cloudhsm(provider)
    client.describe_clusters[:clusters]
          .map(&:to_h).map do |hsm_cluster|
      tags = client.list_tags(
        {
          resource_id: hsm_cluster[:cluster_id],
          max_results: 50 # 50 is the highest we can set this to
        }
      )[:tag_list]
      hsm_cluster.merge(
        {
          _terraform_id: hsm_cluster[:cluster_id],
          _geo_id: tags.find { |tag| tag[:key] == "Name" }&.dig(:value)
        }
      )
    end
  end
end
