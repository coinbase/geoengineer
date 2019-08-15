require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsAcmpcaCertificatePrivateCa do
  let(:aws_client) { AwsClients.acm }

  common_resource_tests(described_class, described_class.type_from_class_name)

  describe '#initialize' do
    it 'creates an acm certificate with correct geo id' do
      resources = GeoEngineer::Resources::AwsAcmpcaCertificatePrivateCa.new(
        "aws_acmpca_certificate_private_ca",
        "abcbhq_dot_net"
      ) {
        domain_name "example.com"
        validation_method "DNS"
        subject_alternative_names ["DomainNameString"]
        tags {
          Name "test"
        }
        options {
          certificate_transparency_logging_preference false
        }
      }
      expect(resources[:_geo_id]).to eql "test"
      expect(resources[:options][:certificate_transparency_logging_preference]).to eql false
    end
  end

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :list_certificates,
        {
          certificate_summary_list: [
            {
              certificate_arn: "arn:aws:iam::certificate-authority/FakeCert1",
              domain_name: "example1.com"
            }
          ]
        }
      )
      aws_client.stub_responses(
        :list_tags_for_certificate,
        {
          tags: [
            {
              key: "Name",
              value: "mycerttag1"
            }
          ]
        }
      )
    end

    it 'creates an array of hashes from the AWS response' do
      resources = GeoEngineer::Resources::AwsAcmpcaCertificatePrivateCa._fetch_remote_resources(nil)
      expect(resources.count).to eql 1

      test_acmpca = resources.first
      expect(test_acmpca[:_geo_id]).to eql "mycerttag1"
      expect(test_acmpca[:_terraform_id]).to eql "arn:aws:iam::certificate-authority/FakeCert1"
      expect(test_acmpca[:certificate_arn]).to eql "arn:aws:iam::certificate-authority/FakeCert1"
    end
  end
end
