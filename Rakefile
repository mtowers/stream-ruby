require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'coveralls/rake/task'


# This is a useful default task:
task :default do
  system "rake --tasks"
end


##
# Build a release of the app (prep for deployment)
namespace :build do
  class NoBuildNumberError < StandardError; end
  class NoVersionNumberError < StandardError; end

  desc "Cut a new the build tag (based on CIRCLE_BUILD_NUM)"
  task :tag do
    # find the version.rb file and get the name of it's parent directory
    dir_name     = Dir.glob('**/**').grep(/version\.rb/).first.split('/')[-2]
    # convert the name of the parent dir to CamelCase
    module_name = dir_name.split(/[-_]/).collect(&:capitalize).join
    # get the module
    version_module  = RealSelf.const_get module_name

    raise NoBuildNumberError, "There is no build number!  You're probably not on CircleCI.  If you really wish to do this, set an environmental variable called CIRCLE_BUILD_NUM and re-run this task." unless version_module::BUILD_NUMBER
    raise NoVersionNumberError, "There is no version number!  Did you remember to load the version.rb file in your Rakefile?" unless version_module::VERSION

    tag = version_module::VERSION

    if 'ubuntu' == ENV['USER'] && 'master' == ENV['CIRCLE_BRANCH']
      puts "On CircleCI and master branch... tagging #{tag}!"
      `git tag #{tag}`
      `git push --tags`
    else
      puts "Not on CircleCI and master branch... not tagging. #{tag}"
    end
  end
end


# Rspec Tasks
TEST_SUITES = [
  { :id => 'unit', :title => 'unit tests', :pattern => 'spec/unit'},
  { :id => 'integration', :title => 'integration tests', :pattern => 'spec/integration'}
]

namespace :test do
  TEST_SUITES.each do |suite|
    desc "run all tests in #{suite[:title]} suite"
    task "#{suite[:id]}" do
      Rake::Task["test:#{suite[:id]}:run"].execute
    end

    RSpec::Core::RakeTask.new("#{suite[:id]}:run") do |t|
      t.pattern       = suite[:pattern]
      t.verbose       = false
      t.fail_on_error = false
      rspec_opts = ["--require", "simplecov"]

      helpers = case suite[:id]
      when 'unit'
        File.join(File.dirname(__FILE__), 'spec/unit/unit_helper.rb')
      when 'integration'
        File.join(File.dirname(__FILE__), 'spec/integration/integration_helper.rb')
      end

      rspec_opts << ["--require", helpers]
      t.rspec_opts = rspec_opts.flatten
    end
  end
end

task :test do
  TEST_SUITES.each do |suite|
    Rake::Task["test:#{suite[:id]}"].invoke
  end

  Rake::Task['coveralls:push'].invoke
end


