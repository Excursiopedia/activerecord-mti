# Delegates missing methods to another object(s).
# May be useful for inheritance mechanisms, decorator pattern or graceful object replacement for refactoring.
#
# Example with delegation of missing methods to an association:
#
#   class A < ActiveRecord::Base
#     def qwe
#       123
#     end
#   end
#
#   class B < ActiveRecord::Base
#     include ActiveRecord::DelegateMissingTo
#
#     belongs_to :a
#     delegate_missing_to :a
#   end
#
#   b = B.new
#   b.qwe # => 123
#
# Additionally you may specify a delegation chain:
#
#   delegate_missing_to :first_priority, :second_priority, :third_priority
#
module DelegateMissingTo
  extend ActiveSupport::Concern

  module ClassMethods
    def delegate_missing_to(*object_names)
      object_names.reverse_each do |object_name|
        define_method "method_missing_with_delegation_to_#{object_name}" do |method, *args, &block|
          object = send(object_name)

          if object.respond_to?(method)
            object.public_send(method, *args, &block)
          else
            send("method_missing_without_delegation_to_#{object_name}", method, *args, &block)
          end
        end

        alias_method_chain :method_missing, "delegation_to_#{object_name}"

        define_method "respond_to_with_delegation_to_#{object_name}?" do |symbol, include_all = false|
          send("respond_to_without_delegation_to_#{object_name}?", symbol, include_all) ||
            send(object_name).respond_to?(symbol)
        end

        alias_method_chain :respond_to?, "delegation_to_#{object_name}"
      end
    end
  end
end
