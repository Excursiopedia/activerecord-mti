require 'delegate_missing_to'
require 'mti'

module ActiveRecord
  class Base
    include DelegateMissingTo
    include ActiveRecord::Mti
  end
end
