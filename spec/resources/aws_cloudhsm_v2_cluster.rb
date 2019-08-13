require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsCloudhsmV2Cluster) do
  common_resource_tests(described_class, described_class.type_from_class_name)
  name_tag_geo_id_tests(GeoEngineer::Resources::AwsCloudhsmV2Cluster)

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      r53r = AwsClients.route53resolver
      stub = r53r.stub_data(
        :describe_clusters, {
          next_token: nil,
          max_results: 10,
          clusters: [{
            backup_policy: "DEFAULT",
            cluster_id: "cluster-mqgqtqrwatj",
            create_timestamp: "2019-07-25 19:27:39 -0500",
            hsms: [{
              availability_zone: "us-east-1a",
              cluster_id: "cluster-mqgqtqrwatj",
              subnet_id: "subnet-baf20c95",
              eni_id: "eni-0c87c1b591cf298ac",
              eni_ip: "10.200.42.69",
              hsm_id: "hsm-m2q2dtteorm",
              state: "ACTIVE",
              state_message: "HSM created."
            }],
            hsm_type: "hsm1.medium",
            pre_co_password: nil,
            security_group: "sg-0a3ff2fb752fa05f9",
            ource_backup_id: nil,
            state: "UNINITIALIZED",
            state_message: nil,
            subnet_mapping: { "us-east-1a": "subnet-baf20c95", "us-east-1b": "subnet-805fe7cb", "us-east-1c": "subnet-838b78de" },
            vpc_id: "vpc-f8e36c9d",
            certificates: {
              cluster_csr: "-----BEGIN CERTIFICATE REQUEST-----[ content removed ]-----END CERTIFICATE REQUEST-----\n",
              hsm_certificate: "-----BEGIN CERTIFICATE-----[ content removed ]-----END CERTIFICATE-----\n",
              aws_hardware_certificate: "-----BEGIN CERTIFICATE-----[ content removed ]-----END CERTIFICATE-----\n",
              manufacturer_hardware_certificate: "-----BEGIN CERTIFICATE-----[ content removed ]-----END CERTIFICATE-----\n",
              cluster_certificate: nil
            }
          }]
        }
      )
      r53r.stub_responses(:describe_clusters, stub)
      remote_resources = GeoEngineer::Resources::AwsCloudhsmV2Cluster._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(1)
    end
  end
end
