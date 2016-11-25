########################################################################
# HasAttributes allows objects to have arbitrary attributes associated with it.
########################################################################
module HasAttributes
  def attributes
    @_attributes = {} unless @_attributes
    @_attributes
  end

  def [](key)
    retrieve_attribute(key.to_s)
  end

  def []=(key, val)
    assign_attribute(key.to_s, [val])
  end

  def delete(key)
    attributes.delete(key.to_s)
  end

  def assign_block(name, *args, &block)
    throw "#{self.class.inspect} cannot handle block"
  end

  def assign_attribute(name, args)
    # this is a setter
    name = name[0...-1] if name.end_with?"="
    val = args.length == 1 ? args[0] : args
    attributes[name] = val
    val
  end

  def retrieve_attribute(name)
    # this is a getter
    val = attributes[name]
    val = attribute_missing(name) if val.nil?
    if val.is_a? Proc
      val = val.call()
      # cache the value to override the Proc
      attributes[name] = val
    end
    val
  end

  def attribute_missing(name)
    nil
  end

  # This method allows attributes to be defined on an instance
  # without explicitly defining which attributes are allowed
  #
  # The flow is:
  # 1. If the method receives a block, it will pass it to the `assign_block` method to be handled.
  #    By default this method will throw an error, but can be overridden by the class.
  # 2. If the method has one or more argument it will assume it is a setter
  #    and store the argument as an attribute.
  # 3. If the method has no arguments it will assume it is a getter and retrieve the value.
  #    If the retrieved value is a `Proc` it will execute it and store the returned value,
  #    this will allow for caching expensive calls and only calling if requested
  def method_missing(name, *args, &block)
    name = name.to_s
    if block_given?
      # A class can override a
      assign_block(name, *args, &block)
    elsif args.length >= 1
      assign_attribute(name, args)
    elsif args.empty?
      retrieve_attribute(name)
    end
  end

  # must override because of Object#timeout
  def timeout(*args)
    method_missing(:timeout, *args)
  end

  # This method creates a set of attributes for terraform to consume
  def terraform_attributes
    attributes
      .select { |k, v| !k.nil? && !k.start_with?('_') }
      .map { |k, v| [k, terraform_attribute_ref(k)] }
      .select { |k, v| !v.nil? }
      .to_h
  end

  def terraform_attribute_ref(k)
    v = retrieve_attribute(k)
    if v.is_a? GeoEngineer::Resource # convert Resource to reference for terraform
      v.to_ref
    elsif v.is_a? Array # map resources if attribute is an array
      v.map { |vi| vi.is_a?(GeoEngineer::Resource) ? vi.to_ref : vi }
    else
      v
    end
  end
end
