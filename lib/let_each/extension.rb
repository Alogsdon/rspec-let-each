# frozen_string_literal: true

module LetEach
  class << self
    # Set to false to stop appending resolved lazy values to failure descriptions
    attr_writer :annotate_failures

    def annotate_failures?
      defined?(@annotate_failures) ? !!@annotate_failures : true
    end

    # short, single line rendering of a value for use in example descriptions
    def describe_value(value, limit = 40)
      text = value.inspect.to_s.gsub(/\s+/, ' ')
      text.length > limit ? "#{text[0, limit - 3]}..." : text
    rescue StandardError => e
      "<#{e.class}: could not inspect>"
    end

    # the `let` name used to memoize a declaration's array proc
    def array_proc_key(name)
      :"_#{name}_array_proc"
    end

    def validate_labels!(labels, length)
      return if labels.nil? || labels.length == length

      raise "labels must have the same length as the values (expected #{length}, got #{labels.length})"
    end

    # example groups build their `full_description` from the parent group's
    # metadata at the time each example/group is created, so mutating a group's
    # metadata before its examples are defined does propagate down
    def append_to_group_description(group, text)
      group.metadata[:description] = "#{group.metadata[:description]}#{text}"
      group.metadata[:full_description] = "#{group.metadata[:full_description]}#{text}"
    end

    # called from an `after` hook, so the generated description (`it { is_expected.to ... }`)
    # has already been assigned and the failure has not been reported yet
    def annotate_failure(example, names, instance)
      return unless annotate_failures?
      return if names.empty?

      values = names.map do |name|
        "#{name} = #{describe_value(instance.send(name))}"
      rescue StandardError => e
        "#{name} = <#{e.class}>"
      end
      example.metadata[:full_description] = "#{example.metadata[:full_description]} [#{values.join(', ')}]"
    end

    # builds the cartesian nesting of contexts for the given declarations,
    # in declaration order (first declared = outermost), yielding each innermost group
    def expand_contexts(group, declarations, &leaf_block)
      declaration = declarations.first
      return leaf_block.call(group) unless declaration

      rest = declarations.drop(1)
      declaration.length.times do |index|
        group.context(declaration.context_description(index)) do
          declaration.define_lets(self, index)
          LetEach.expand_contexts(self, rest, &leaf_block)
        end
      end
    end
  end

  # one `let_each` declaration, also the chainable object `let_each` returns (for `with`).
  # a group's declarations are collected in order and then expanded together,
  # so the contexts nest in the order they were written
  class Declaration
    attr_reader :length, :unresolved_names

    def initialize(example_group, name, length, labels:, array:)
      @example_group = example_group
      @name = name
      @length = length
      @array_proc_key = LetEach.array_proc_key(name)
      @labels = labels
      @array = array
      @withs = []
      # names whose value we can't show in the context name (lazy, unlabelled);
      # these get resolved and reported on failure instead.
      # read at run time, so `with` chains added after the first example still count
      @unresolved_names = []
      @unresolved_names << name unless labels || array
    end

    # the values we already know at load time go straight into the context name
    def context_description(index)
      if @labels
        "when #{@name}[#{index}] = #{@labels[index]}"
      elsif @array
        "when #{@name}[#{index}] = #{LetEach.describe_value(@array[index])}"
      else
        "when #{@name}[#{index}]"
      end
    end

    def define_lets(group, index)
      # locals, because the `let` block runs on the example instance where our ivars don't exist
      name = @name
      array_proc_key = @array_proc_key
      group.let(name) { send(array_proc_key)[index] }
      @withs.each { |with_proc| group.instance_exec(index, &with_proc) }
    end

    def with(name, array = nil, labels: nil, &lazy_array_block)
      if lazy_array_block
        # length is assumed to be the same as the base let_each
        raise 'dont need to provide a second argument when providing a lazy array block' if array
      else
        lazy_array_block = -> { array }
      end
      LetEach.validate_labels!(labels, @length)

      # same rule as `let_each`: describe what we know now, report the rest on failure
      descriptions = labels || array&.map { |value| LetEach.describe_value(value) }
      @unresolved_names << name unless descriptions

      array_proc_key = LetEach.array_proc_key(name)
      # can memoize the proc right away
      @example_group.let(array_proc_key, &lazy_array_block)
      # we can't unload the main `let` until we're in the context
      # so just store the proc
      @withs << lambda do |index|
        # self is the only variable not closured here
        # we'll instance_exec this on the context
        let(name) { send(array_proc_key)[index] }
        # runs before any example is defined in this context, so it still propagates
        LetEach.append_to_group_description(self, ", #{name} = #{descriptions[index]}") if descriptions
      end

      self
    end
  end

  module Extension
    # Usage:
    # lazy signature
    # let_each(:x, 2) { [let_foo, let_bar] }
    #   .with(:y) { [foo_expected, bar_expected] }
    #
    # eager signature
    # let_each(:y, [eager_foo, eager_bar])
    #
    # labelled signature (any signature)
    # let_each(:x, 2, labels: %w[empty full]) { [let_foo, let_bar] }
    #
    # the lazy_array_block plays nice with other `let`s, but contexts are eagerly evaluated
    # so we need to provide a "length" to know how many contexts to spawn
    # then the array values can still be lazily evaluated
    # alternatively, just pass an eager array if you don't need the laziness on the values
    #
    # There is possibly some overhead to using this in its present state.
    # It could be optimized more but this is just my POC for the feature.
    # Careful not to exponentially spawn contexts, every call to this helper will multiply the number of examples
    # In a future feature we may allow for automatically limiting the number of contexts,
    # then trending towards `let(:x) { [foo, bar].sample }`
    # AFAIK, this works in nested contexts, and with shared_examples/contexts,
    # but I'd suggest pushing the usage as close to the actual examples as possible, so you don't enumerate too much
    #
    # I've added a chainable `with` method to allow for parallely assigned lets
    # this can be also be chained multiple times
    #
    # Naming: values that are known when the contexts are built (eager arrays, or
    # explicit `labels:`) are baked into the context description, e.g. `when x[0] = 33`.
    # Values that can only be known at run time (lazy blocks) get appended to the
    # description of failing examples instead, e.g. `... [x = 7, y = 50]`.
    def let_each(name, length_or_array, labels: nil, &lazy_array_block)
      if lazy_array_block
        raise 'must specify the length when providing a lazy array block' unless length_or_array.is_a?(Integer)

        length = length_or_array
        array = nil
      else
        raise 'must provide an array when not providing a lazy array block' unless length_or_array.respond_to?(:length)

        array = length_or_array
        length = array.length
        lazy_array_block = -> { array }
      end
      LetEach.validate_labels!(labels, length)

      array_proc_key = LetEach.array_proc_key(name)
      # I just didn't handle this case. doing so is a bit tricky with the approach I used
      # we'd need to replay the `it` overrides with the changed value removed
      raise "let_each already used for key: #{name}" if instance_methods.include?(array_proc_key)
      # `it` was already used in this context but we didn't get a chance to override it yet
      if defined?(@context_leafs)
        raise 'let_each used after an example. either nest in a new context or arrange `let_each` above examples'
      end

      # behavior is also unexpected if we `let` with this same name,
      # but I'm not going out of my way to guard against that

      let(array_proc_key, &lazy_array_block) # memoize the array proc result
      declaration = Declaration.new(self, name, length, labels: labels, array: array)
      let_each_declarations << declaration
      install_let_each_it_override
      declaration
    end

    private

    # declarations from enclosing groups (the parent group is our superclass) apply
    # here too, so we start from a copy of theirs and expand the whole set at once
    def let_each_declarations
      return @let_each_declarations if defined?(@let_each_declarations)

      inherited = superclass.respond_to?(:let_each_declarations, true) ? superclass.send(:let_each_declarations) : []
      @let_each_declarations = inherited.dup
    end

    # RSpec's own `it`, captured before any group in this chain overrode it
    def let_each_base_it
      return @let_each_base_it if defined?(@let_each_base_it)

      @let_each_base_it =
        if superclass.respond_to?(:let_each_base_it, true)
          superclass.send(:let_each_base_it)
        else
          method(:it).unbind
        end
    end

    def install_let_each_it_override
      # each group expands every declaration it can see, so we only need one override
      # per group, and it always delegates to the untouched `it`
      return if defined?(@let_each_it_installed)

      @let_each_it_installed = true
      base_it = let_each_base_it
      declarations = let_each_declarations

      define_singleton_method(:it) do |*args, &block|
        if defined?(@context_leafs)
          # we make a lot of contexts with this helper
          # this is an improvement to reuse them when possible
          # (when `it` is used multiple times in the same context)
          # should be able to do something similar with `context` but I'm not worried about it right now
          # new context = caches are dumped anyway, so there's probably not much to gain
          @context_leafs.each do |leaf|
            base_it.bind_call(leaf, *args, &block)
          end
        else
          # first time we're calling `it` in this context
          # instance variable will be inaccessible from within these context blocks
          # so we assign the local variable too
          @context_leafs = context_leafs = []
          LetEach.expand_contexts(self, declarations) do |leaf|
            # innermost context: one hook reports every unresolved value, in declaration order
            leaf.after do |example|
              next unless example.exception

              LetEach.annotate_failure(example, declarations.flat_map(&:unresolved_names), self)
            end
            base_it.bind_call(leaf, *args, &block)
            context_leafs << leaf
          end
        end
      end
    end
  end
end
