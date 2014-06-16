module RSpec::EM
  class AsyncSteps < Module
    
    def included(klass)
      klass.__send__(:include, Scheduler)
    end
    
    def method_added(method_name)
      async_method_name = "async_#{method_name}"

      return if instance_methods(false).map { |m| m.to_s }.include?(async_method_name) or
                method_name.to_s =~ /^async_/
      
      module_eval <<-RUBY
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

    end
    
  end
end

class RSpec::Core::Example
  hook_method = %w[with_around_hooks with_around_each_hooks with_around_example_hooks].find { |m| instance_method(m) rescue nil }
  after_method = %w[run_after_each run_after_example].find { |m| instance_method(m) rescue nil }

  class_eval <<-end_eval, __FILE__, __LINE__ + 1
    alias :synchronous_run :#{hook_method}
    
    def #{hook_method}(*args, &block)
      if @example_group_instance.is_a?(RSpec::EM::AsyncSteps::Scheduler)
        begin
          EventMachine.run { synchronous_run(*args, &block) }
        ensure
          #{after_method}
        end
      else
        synchronous_run(*args, &block)
      end
    end

    alias :run_after_orig :#{after_method}

    def #{after_method}
      run_after_orig unless EventMachine.reactor_running?
    end

  end_eval

end
