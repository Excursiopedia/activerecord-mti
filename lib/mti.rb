# Multiple Table Inheritance (MTI)
#
# Say, you have a base model (Fruit) and its implementations (Apple & Banana).
# STI is not suitable because you have to keep Apple's & Banana's specific fields in one table (fruits).
# MTI enables you to keep a clear database schema with a table for common fields only (fruits)
# and two tables for specific fields only (apples & bananas).
# This implementation is based on delegation pattern and doesn't use class inheritance.
#
# Example:
#
#   class Fruit < ActiveRecord::Base
#     mti_base
#   end
#
#   class Apple < ActiveRecord::Base
#     mti_implementation_of :fruit
#   end
#
#   class Banana < ActiveRecord::Base
#     mti_implementation_of :fruit
#   end
#
module ActiveRecord::Mti
  extend ActiveSupport::Concern

  module ClassMethods
    def mti_base
      class_attribute :mti_name
      self.mti_name = self.to_s.underscore.to_sym

      # Always fetch with the implementation
      default_scope lambda { includes(mti_name) }

      # Implementation model association
      belongs_to mti_name,
                 polymorphic: true,
                 inverse_of: mti_name

      # Override ActiveRecord's instantiation method
      # which builds an object from a record
      # Return the base class object when in "base instance mode"
      # and the implementation object otherwise
      def self.instantiate(*_)
        if Thread.current[:base_instance_mode]
          super
        else
          super.public_send(mti_name)
        end
      end

      # Thread safe execution of a block in a "base instance mode"
      def self.as_base_instance
        Thread.current[:base_instance_mode] = true
        yield.tap do
          Thread.current[:base_instance_mode] = false
        end
      end
    end

    def mti_implementation_of(mti_base_name)
      class_attribute :mti_base
      self.mti_base = mti_base_name.to_s.classify.constantize

      # Base model association
      has_one mti_base_name.to_sym,
              :as => mti_base_name.to_sym,
              :autosave => true,
              :dependent => :destroy,
              :validate => true,
              :inverse_of => mti_base_name.to_sym

      # When calling the base object from the implementation
      # switch the base's class to the "base instance mode"
      # to receive the base class object instead of another
      # implementation object and avoid an infinite loop
      define_method "#{mti_base_name}_with_reverse" do          # def role_with_reverse
        mti_base.as_base_instance do                            #   Role.as_base_instance do
          send("#{mti_base_name}_without_reverse")              #     role_without_reverse
        end                                                     #   end
      end                                                       # end
      alias_method_chain mti_base_name, :reverse                # alias_method_chain :role, :reverse

      # Auto build base model
      define_method "#{mti_base_name}_with_autobuild" do        # def role_with_autobuild
        public_send("#{mti_base_name}_without_autobuild") ||    #   role_without_autobuild ||
            public_send("build_#{mti_base_name}")               #     build_role
      end                                                       # end
      alias_method_chain mti_base_name, :autobuild              # alias_method_chain :role, :autobuild

      # Delegate attributes
      if ActiveRecord::Base.connection.table_exists?(mti_base)
        mti_base.content_columns.map(&:name).each do |attr|
          delegate attr, "#{attr}=", "#{attr}?",
                   :to => mti_base_name.to_sym
        end
      end

      # Delegate associations
      mti_base.reflections.keys
              .tap { |k| k.delete(mti_base_name.to_sym) }
              .each do |association|
        delegate association, "#{association}=",
                 :to => mti_base_name.to_sym
      end

      delegate_missing_to mti_base_name

      accepts_nested_attributes_for mti_base_name

      define_method "#{mti_base_name}_id" do
        public_send(mti_base_name).id
      end
    end
  end
end
