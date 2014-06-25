require 'spec_helper'

describe '.delegate_missing_to' do
  before :all do
    class DummyWorker
      def do_work(*_)
      end
    end

    class DummyDelegator
      include DelegateMissingTo

      delegate_missing_to :worker

      def worker
        @worker ||= DummyWorker.new
      end
    end
  end

  subject(:delegator) { DummyDelegator.new }
  let(:params) { [:some, :params] }

  it 'should delegate missing method call' do
    expect(delegator.worker).to receive(:do_work).with(*params)
    delegator.do_work(*params)
  end
end
