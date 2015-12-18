require 'thor'

module BrewGem
  class Cli < Thor
    COMMANDS = {
      install: 'Install a gem (from RubyGems, local dir, local .gem, or github)',
      update: 'Update a gem installed from RubyGems',
      uninstall: 'Uninstall a gem installed from RubyGemss'
    }

    desc 'install [<gem-name>] [<version>] [--local=<path-to-local-dir-or-.gem>] [--github=<git@github.com:project/repo.git]', 
          COMMANDS[:install]
    method_option :local, type: 'string'
    method_option :github, type: 'string'
    method_option :verbose, :type => :boolean
    def install(gem_name = nil, version = nil)
      BrewGem.install(gem_name, version, options)
    end

    desc 'update <gem-name>', COMMANDS[:update]
    method_option :verbose, :type => :boolean
    def update(gem_name)
      BrewGem.update(gem_name)
    end

    desc 'uninstall <gem-name>', COMMANDS[:uninstall]
    method_option :verbose, :type => :boolean
    def uninstall(gem_name)
      BrewGem.uninstall(gem_name)
    end
  end
end
