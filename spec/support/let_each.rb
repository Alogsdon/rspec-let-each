module LetEachHelper
  # Usage:
  # lazy signature
  # let_each(:x, 2) { [let_foo, let_bar] }
  #
  # eager signature
  # let_each(:y, [eager_foo, eager_bar])
  #
  # the lazy_array_block plays nice with other `let`s, but contexts are eagerly evaluated
  # so we need to provide a "length" to know how many contexts to spawn
  # then the array values can still be lazily evaluated
  # alternatively, just pass an eager array if you don't need the laziness on the values
  #
  # There is possibly some overhead to using this in its present state. It could be optimized more but this is just my POC for the feature.
  # Careful not to exponentially spawn contexts, every call to this helper will multiply the number of examples
  # In a future feature we may allow for automatically limiting the number of contexts, then trending towards `let(:x) { [foo, bar].sample }`
  # AFAIK, this works in nested contexts, and with shared_examples/contexts,
  # but I'd suggest pushing the usage as close to the actual examples as possible, so you don't enumerate too much
  #
  def let_each(name, length_or_array, &lazy_array_block)
    if lazy_array_block
      raise 'must specify the length when providing a lazy array block' unless length_or_array.is_a?(Integer)
      length = length_or_array
    else
      raise 'must provide an array when not providing a lazy array block' unless length_or_array.respond_to?(:length)
      array = length_or_array
      length = array.length
      lazy_array_block = -> { array }
    end

    array_proc_key = :"_#{name}_array_proc"
    # I just didn't handle this case. doing so is a bit tricky with the approach I used
    # we'd need to replay the `it` overrides with the changed value removed
    raise "let_each already used for key: #{name}" if instance_methods.include?(array_proc_key)
    # `it` was already used in this context but we didn't get a chance to override it yet
    if defined?(@context_leafs)
      raise 'let_each used after an example. either nest in a new context or arrange `let_each` above examples'
    end

    # behavior is also unexpected if we `let` with this same name, but I'm not going out of my way to guard against that

    let(array_proc_key, &lazy_array_block) # memoize the array proc result
    # `super` would only work the first time we call let_each per context. so we'll just closure it every time
    old_it = method(:it).unbind
    define_singleton_method(:it) do |*args, &block|
      if defined?(@context_leafs)
        # we make a lot of contexts with this helper
        # this is an improvement to reuse them when possible
        # (when `it` is used multiple times in the same context)
        # should be able to do something similar with `context` but I'm not worried about it right now
        # new context = caches are dumped anyway, so there's probably not much to gain
        @context_leafs.each do |leaf|
          old_it.bind_call(leaf, *args, &block)
        end
      else
        # first time we're calling `it` in this context
        # instance variable will be inaccessible from within these context blocks
        # so we assign the local variable too
        @context_leafs = context_leafs = []
        length.times do |i|
          context "with #{name}[#{i}]" do
            let(name) { send(array_proc_key)[i] }

            old_it.bind_call(self, *args, &block)
            context_leafs << self
          end
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.extend LetEachHelper
end
