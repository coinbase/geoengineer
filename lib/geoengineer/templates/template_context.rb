# Helper for injecting custom values for variables in templates.
class TemplateContext
  def self.build(options = nil)
    options = {} if options.nil?
    context = TemplateContext.new(options)

    b = context._binding
    b.define_singleton_method(:merge) do |o|
      context.merge(o)
    end
    b
  end

  attr_reader :options
  def initialize(options)
    @options = options
  end

  def merge(alt)
    @options.merge!(alt)
  end

  def method_missing(method_name, *_args, &_block) # rubocop:disable Style/MethodMissingSuper
    throw "Unable to find #{method_name} in current context" if @options[method_name].nil?
    @options[method_name]
  end

  def respond_to_missing?(method_name, *_args)
    @options.key?(method_name) || super
  end

  def _binding
    binding
  end
end
