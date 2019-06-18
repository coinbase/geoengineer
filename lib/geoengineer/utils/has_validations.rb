require 'netaddr'

########################################################################
# HasValidations provides methods to enable validations
########################################################################
module HasValidations
  MAX_POLICY_LENGTH = 5120

  def self.included(base)
    base.extend(ClassMethods)
  end

  # ClassMethods
  module ClassMethods
    def validations
      all_validations = []
      all_validations.concat(@_validations) if @_validations
      # inherit validations
      sclazz = self.superclass
      all_validations.concat(sclazz.validations) if sclazz.respond_to?(:validations)
      all_validations
    end

    def validate(method_name_or_proc)
      @_validations = [] unless @_validations
      @_validations << method_name_or_proc
    end
  end

  # This method will return a list of errors if not valid, or nil
  def errors
    execute_lifecycle(:before, :validation) if self.respond_to? :execute_lifecycle
    errs = []
    self.class.validations.each do |validation|
      errs << (validation.is_a?(Proc) ? self.instance_exec(&validation) : self.send(validation))
    end
    # remove nils
    errs = errs.flatten.select { |x| !x.nil? }
    errs
  end

  # Validation Helper Methods
  def validate_required_attributes(keys)
    errs = []
    keys.each do |key|
      errs << "#{key} attribute nil for #{self}" if self[key].nil?
    end
    errs
  end

  # Validates CIDR block format
  # Returns error when argument fails validation
  def validate_cidr_block(cidr_block)
    return "Empty cidr block" if cidr_block.nil? || cidr_block.empty?
    return if NetAddr::CIDR.create(cidr_block)
  rescue NetAddr::ValidationError
    return "Bad cidr block \"#{cidr_block}\" #{for_resource}"
  end

  def validate_policy_length(policy, max_length = MAX_POLICY_LENGTH)
    return unless policy.to_s.length >= max_length
    "Policy #{name} is too large - currently #{policy.to_s.length}, max length is #{max_length}"
  end

  # Validates that at least one of the specified attributes is present
  def validate_at_least_one_present(attributes)
    errs = []
    present = attributes.select { |attribute| !self[attribute].nil? }.count
    errs << "At least one of #{attributes.join(', ')} must be defined" unless present.positive?
    errs
  end

  # Validates that ONLY one of the specified attributes is present
  def validate_only_one_present(attributes)
    errs = []
    present = attributes.select { |attribute| !self[attribute].nil? }.count
    errs << "Only one of #{attributes.join(', ')} can be defined" unless present == 1
    errs
  end
end
