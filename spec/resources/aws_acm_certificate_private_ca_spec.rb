require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsAcmCertificatePrivateCa do
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe '#initialize' do
    it 'creates an acm certificate with correct geo id' do
      resources = GeoEngineer::Resources::AwsAcmCertificatePrivateCa.new(
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
end
