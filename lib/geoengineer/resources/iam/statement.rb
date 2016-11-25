module GeoEngineer::IAM
  ########################################################################
  # A Statement object is a single iam policy statement with a Sid,
  # effect, action, and condition. Used to assist validating IAM policies.
  ########################################################################
  class Statement
    attr_reader :sid, :action, :effect

    def initialize(raw)
      @action = raw["Action"]
      @effect = raw["Effect"]
      @raw = raw
      @sid = raw["Sid"]
    end

    def secure_transport?
      secure_transport = @raw.dig('Condition', 'Bool', 'aws:SecureTransport')
      secure_transport == "true"
    end

    def ip_restrictions
      cidr_blocks = []
      cidr_blocks << @raw.dig('Condition', 'IpAddress', 'aws:SourceIP')
      cidr_blocks << @raw.dig('Condition', 'IpAddressIfExists', 'aws:SourceIP')
      cidr_blocks.flatten.compact
    end

    def ip_restriction_exists?
      return true unless ip_restrictions.empty?
    end

    def vpc_restrictions
      vpcs = []
      vpcs << @raw.dig('Condition', 'StringEqualsifExists', 'aws:sourceVpce')
      vpcs << @raw.dig('Condition', 'ForAnyValue:StringEquals', 'aws:sourceVpce')
      vpcs.flatten.compact
    end

    def vpc_restriction_exists?
      return true unless vpc_restrictions.empty?
    end
  end
end
