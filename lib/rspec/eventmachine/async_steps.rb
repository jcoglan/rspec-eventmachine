module RSpec::EM
  class AsyncSteps < Module
    
    def included(klass)
      klass.__send__(:include, Scheduler)
    end
    
    def method_added(method_name)
      async_method_name = "async_#{method_name}"

      return if instance_methods(false).map { |m| m.to_s }.include?(async_method_name) or
                method_name.to_s =~ /^async_/

      module_eval <<-RUBY, __FILE__, __LINE__ + 1
        alias :#{async_method_name} :#{method_name}

        def #{method_name}(*args)
          __enqueue__([#{async_method_name.inspect}] + args)
        end
      RUBY
    end
    
    module Scheduler
      def __enqueue__(args)
        @__step_queue__ ||= []
        @__step_queue__ << args
        return if @__running_steps__
        @__running_steps__ = true
        EventMachine.next_tick { __run_next_step__ }
      end
      
      def __run_next_step__
        step = @__step_queue__.shift
        return EventMachine.stop unless step
        
        method_name, args = step.shift, step
        begin
          method(method_name).call(*args) { __run_next_step__ }
        rescue Object
          __end_steps__
          raise
        end
      end
      
      def __end_steps__
        @__step_queue__ = []
        __run_next_step__
      end
      
      def verify_mocks_for_rspec
        EventMachine.reactor_running? ? false : super
      end
      
      def teardown_mocks_for_rspec
        EventMachine.reactor_running? ? false : super
      end

      def verify_step_queue
        if @__step_queue__&.size&.positive?
          raise RuntimeError.new("EventMachine terminated before the end of the spec. #{@__step_queue__.size} async steps left to execute: #{@__step_queue__.map(&:first).join(', ')}")
        end
      end
    end
    
  end
end

class RSpec::Core::Example
  hook_method = %w[with_around_hooks with_around_each_hooks with_around_example_hooks].find { |m| instance_method(m) rescue nil }

  class_eval <<-RUBY, __FILE__, __LINE__ + 1
    alias :synchronous_run :#{hook_method}
    
    def #{hook_method}(*args, &block)
      if @example_group_instance.is_a?(RSpec::EM::AsyncSteps::Scheduler)
        EventMachine.run { synchronous_run(*args, &block) }
        @example_group_instance.verify_mocks_for_rspec
        @example_group_instance.teardown_mocks_for_rspec
        @example_group_instance.verify_step_queue
      else
        synchronous_run(*args, &block)
      end
    end
  RUBY
end
