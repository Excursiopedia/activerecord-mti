require 'spec_helper'

describe 'MTI' do
  before :all do
    ActiveRecord::Base.establish_connection(:adapter => :sqlite3, :database => 'mti_spec_db')

    ActiveRecord::Schema.define do
      self.verbose = false

      create_table :owners, force: true do |t|
        t.string :name
      end

      create_table :devices, force: true do |t|
        t.string :name
        t.integer :owner_id
        t.integer :device_id
        t.string :device_type
      end

      create_table :computers, force: true do |t|
        t.string :cpu_model
      end

      create_table :cameras, force: true do |t|
        t.float :matrix_size
      end
    end

    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute(<<-SQL)
        INSERT INTO owners (id, name)
        VALUES (1, 'john doe');
      SQL

      ActiveRecord::Base.connection.execute(<<-SQL)
        INSERT INTO devices (id, name, owner_id, device_id, device_type)
        VALUES (1, 'mac book pro', 1, 1, 'Computer');
      SQL

      ActiveRecord::Base.connection.execute(<<-SQL)
        INSERT INTO computers (id, cpu_model)
        VALUES (1, 'core i7');
      SQL

      ActiveRecord::Base.connection.execute(<<-SQL)
        INSERT INTO devices (id, name, owner_id, device_id, device_type)
        VALUES (2, 'canon 550d', 1, 1, 'Camera');
      SQL

      ActiveRecord::Base.connection.execute(<<-SQL)
        INSERT INTO cameras (id, matrix_size)
        VALUES (1, 18.7);
      SQL
    end

    class Owner < ActiveRecord::Base; end

    class Device < ActiveRecord::Base
      mti_base

      belongs_to :owner

      def switch_on
        :on
      end
    end

    class Computer < ActiveRecord::Base
      mti_implementation_of :device

      def run_program
        :done
      end
    end

    class Camera < ActiveRecord::Base
      mti_implementation_of :device

      def make_shot
        :click
      end
    end
  end

  after(:all) do
    ActiveRecord::Schema.define do
      drop_table :devices
      drop_table :computers
      drop_table :cameras
    end
  end

  describe 'base' do
    it 'finders should return the implementation' do
      computer = Device.find_by_name('mac book pro')
      expect(computer).to be_kind_of(Computer)
    end
  end

  describe 'implementation' do
    subject(:camera) { Camera.find(1) }

    it 'should have attributes of the implementation' do
      expect(camera.matrix_size).to eq(18.7)
    end

    it 'should have attributes of the base object' do
      expect(camera.name).to eq('canon 550d')
    end

    it 'should act as an implementation' do
      expect(camera.make_shot).to eq(:click)
    end

    it 'should act as a base object' do
      expect(camera.switch_on).to eq(:on)
    end

    it 'should return the base object on demand' do
      expect(camera.device).to be_kind_of(Device)
    end

    it 'should respond to base object\'s associations' do
      expect(camera.owner.name).to eq('john doe')
    end
  end

  describe 'building a model' do
    before do
      Computer.create! do |c|
        c.name = 'mac book air'
        c.cpu_model = 'core i3'
      end
    end

    it 'should build both base and implementation' do
      expect(Device.where(name: 'mac book air').first.cpu_model).to eq('core i3')
    end
  end
end
