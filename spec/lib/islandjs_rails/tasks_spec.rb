require_relative '../../spec_helper'
require 'islandjs_rails/tasks'

RSpec.describe "Islandjs Rake Tasks" do
  before(:all) do
    unless Rake::Task.task_defined?('environment')
      Rake::Task.define_task('environment') { }
    end

    unless Rake::Task.task_defined?('islandjs:init')
      load File.expand_path('../../../../lib/islandjs_rails/tasks.rb', __FILE__)
    end
  end

  before(:each) do
    Rake.application.tasks.each(&:reenable)
  end

  describe "islandjs:init" do
    it "calls IslandjsRails.init!" do
      expect(IslandjsRails).to receive(:init!)
      Rake.application.invoke_task("islandjs:init")
    end
  end

  describe "islandjs:version" do
    it "outputs the version" do
      expect {
        Rake.application.invoke_task("islandjs:version")
      }.to output(/IslandjsRails #{IslandjsRails::VERSION}/).to_stdout
    end
  end
end
