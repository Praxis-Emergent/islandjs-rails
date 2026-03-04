require 'spec_helper'

RSpec.describe IslandjsRails do
  describe 'VERSION' do
    it 'is 2.0.0' do
      expect(IslandjsRails::VERSION).to eq('2.0.0')
    end

    it 'is a semver string' do
      expect(IslandjsRails::VERSION).to match(/\d+\.\d+\.\d+/)
    end
  end

  describe 'Error' do
    it 'inherits from StandardError' do
      expect(IslandjsRails::Error).to be < StandardError
    end

    it 'can be raised and rescued' do
      expect { raise IslandjsRails::Error, 'test' }.to raise_error(IslandjsRails::Error, 'test')
    end
  end

  describe '.configuration' do
    it 'returns a Configuration instance' do
      expect(IslandjsRails.configuration).to be_a(IslandjsRails::Configuration)
    end

    it 'memoizes the instance' do
      config1 = IslandjsRails.configuration
      config2 = IslandjsRails.configuration
      expect(config1).to be(config2)
    end
  end

  describe '.configure' do
    it 'yields the configuration' do
      IslandjsRails.configure do |config|
        expect(config).to be_a(IslandjsRails::Configuration)
      end
    end
  end

  describe '.core' do
    it 'returns a Core instance' do
      expect(IslandjsRails.core).to be_a(IslandjsRails::Core)
    end

    it 'memoizes the instance' do
      core1 = IslandjsRails.core
      core2 = IslandjsRails.core
      expect(core1).to be(core2)
    end
  end

  describe '.init!' do
    it 'delegates to core.init!' do
      expect(IslandjsRails.core).to receive(:init!)
      IslandjsRails.init!
    end
  end

  describe 'Rails integration' do
    it 'defines the Railtie when Rails is present' do
      expect(IslandjsRails.const_defined?(:Railtie)).to be true
    end

    it 'defines RailsHelpers when Rails is present' do
      expect(IslandjsRails.const_defined?(:RailsHelpers)).to be true
    end
  end
end
