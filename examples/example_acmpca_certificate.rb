## Run this from the root directory of geo.
##
##  ./bin/geo plan examples/example_acmpca_certificate.rb
##
GeoCLI.instance.env_name = "geoexperiments"
GeoCLI.instance.environment = GeoEngineer::Environment.new("geoexperiments")
project = GeoCLI.instance.environment.project("org","geoexperiments"){
    environments "geoexperiments"
}

cert = project.resource("aws_acmpca_certificate_private_ca", "acbhq_dot_net") {
    tags {
        Name "acbhq.net"
    }
    domain_name "example.com"
    validation_method "DNS"
    subject_alternative_names ["DomainNameString"]
    certificate_authority_arn "arn:aws:acmpca::123456789012:MyTestCA" #Not a real arn
    options {
        certificate_transparency_logging_preference false
    }
}

p cert
