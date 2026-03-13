require 'spec_helper'

RSpec.describe IslandjsRails::CLI do
  let(:cli) { described_class.new }

  describe '#init' do
    it 'calls IslandjsRails.init!' do
      expect(IslandjsRails).to receive(:init!)
      cli.init
    end
  end

  describe '#version' do
    it 'outputs the version' do
      expect { cli.version }.to output(/IslandjsRails #{IslandjsRails::VERSION}/).to_stdout
    end
  end
end
