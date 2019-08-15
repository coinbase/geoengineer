## Run this from the root directory of geo.
##
##  ./bin/geo plan examples/example_acmpca.rb
##
GeoCLI.instance.env_name = "geoexperiments"
GeoCLI.instance.environment = GeoEngineer::Environment.new("geoexperiments")
project = GeoCLI.instance.environment.project("org","geoexperiments"){
    environments "geoexperiments"
}


acmpca = project.resource("aws_acmpca_certificate_authority", "acbhq_dot_net") {
    certificate_authority_configuration {
       key_algorithm      "RSA_4096"
       signing_algorithm "SHA512WITHRSA"

       subject {
         common_name  "acbhq.net"
         country "US"
         state "California"
         organization "ABCCompany"
       }
     }
    type "ROOT"
    tags {
      name "acbhq.net"
    }
  }

p acmpca
