require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsAcmpcaCertificateAuthority do
  let(:aws_client) { AwsClients.acmpca }

  common_resource_tests(described_class, described_class.type_from_class_name)

  before { aws_client.setup_stubbing }

  describe '#initialize' do
    it 'should create an acmpca resource with correct geo id' do
      resources = GeoEngineer::Resources::AwsAcmpcaCertificateAuthority.new(
        "aws_acmpca_certificate_authority",
        "abcbhq_dot_net"
      ) {
        type "ROOT"
        certificate_authority_configuration [
          {
            subject: [{
              common_name: "abcbhq.net"
            }]
          }
        ]
      }
      expect(resources[:_geo_id]).to eql "ROOT::abcbhq.net"
    end
  end

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :list_certificate_authorities,
        {
          certificate_authorities: [
            {
              arn: "arn:aws:iam::123456789012:user/FakeUser1",
              type: "ROOT",
              certificate_authority_configuration:
                {
                  key_algorithm: "RSA_4096",
                  signing_algorithm: "SHA512WITHRSA",
                  subject: {
                    common_name: "example1.com"
                  }
                }
            },
            {
              arn: "arn:aws:iam::123456789012:user/FakeUser2",
              type: "SUBORDINATE",
              certificate_authority_configuration:
                {
                  key_algorithm: "RSA_4096",
                  signing_algorithm: "SHA512WITHRSA",
                  subject: {
                    common_name: "example1.com"
                  }
                }
            }
          ]
        }
      )
    end

    it 'should create an array of hashes from the AWS response' do
      resources = GeoEngineer::Resources::AwsAcmpcaCertificateAuthority._fetch_remote_resources(nil)
      expect(resources.count).to eql 2

      test_acmpca = resources.first
      expect(test_acmpca[:_geo_id]).to eql "ROOT::example1.com"
      expect(test_acmpca[:_terraform_id]).to eql "arn:aws:iam::123456789012:user/FakeUser1"
      expect(test_acmpca[:certificate_authority_configuration][:key_algorithm]).to eql "RSA_4096"
      expect(test_acmpca[:certificate_authority_configuration][:signing_algorithm]).to eql "SHA512WITHRSA"
      expect(test_acmpca[:certificate_authority_configuration][:subject][:common_name]).to eql "example1.com"
    end
  end
end
