require 'erb'
require 'tempfile'

module BrewGem
  class << self
    def install(options)
      perform(:install, options)
    end

    def update(options)
      perform(:update, options)
    end

    def uninstall(options)
      perform(:uninstall, options)
    end

    def require_all_under(dir, recursive: true)
      glob_path = File.join("#{dir}", recursive ? '**' : '', '*')
      Dir.glob(glob_path) do |file_path|
        require file_path if File.file?(file_path)
      end
    end

    private
    # TODO: Refactor into several methods, and for that need to
    # run ERB from hash bindings instead of local method bindings
    def perform(command, options = {})
      name, version = options.values_at(:name, :version)
      
      ENV['HOMEBREW_VERBOSE']='true' if options[:verbose]
      if options[:local]
        local_path = File.expand_path(options[:local])

        if /\.gem$/ =~ local_path
          # install from local gem
          name, version = local_path.match(/.*\/([^-]+)-(.*)\.gem$/)[1..2]
        else
          # install from local dir
          gemspec_name = `ls #{File.join(local_path, '*')}.gemspec`.chomp

          # build local gem
          Dir.chdir(local_path) do
            run "gem build #{gemspec_name}"
          end

          gem_path = `ls #{File.join(local_path, '*')}.gem`.chomp

          # recursively call self to install from local gem
          install(local: gem_path)
          return
        end
      elsif options[:git]
        # clone from github and build gem
        github_gem_path = options[:git]
        name = github_gem_path.match(/.*\/(.*)\.git$/)[1]
        target_dir_name = File.join(Dir.tmpdir, "build-#{name}-#{rand(100000000)}")
        git_command = "git clone #{github_gem_path} #{target_dir_name}"
        git_command += " --single-branch -b #{options[:ref]}" if options[:ref]
        run git_command
        # recursively call self to install from local dir
        install(local: target_dir_name)
        return
      else
        # install from rubygems
        gems = `gem list --remote "^#{name}$"`.lines
        unless gems.detect { |f| f =~ /^#{name} \(([^\s,]+).*\)/ }
          abort "Could not find a valid gem '#{name}'"
        end
      end

      klass = name.capitalize.gsub(/[-_.\s]([a-zA-Z0-9])/) { $1.upcase }.gsub('+', 'x')
      user_gemrc = "#{ENV['HOME']}/.gemrc"

      template = ERB.new(File.read(File.expand_path("../../config/templates/formula.rb.erb", __FILE__)))

      filename = File.join Dir.tmpdir, "#{name}.rb"

      begin
        open(filename, 'w') do |f|
          f.puts template.result(binding)
        end

        run "brew #{command} #{filename}"
      ensure
        File.unlink filename
      end
    end
    
    def run(command, options={})
      if command.is_a? Array
        command.each do |single_command|
          break unless run single_command
        end
      else
        puts "[brewgem] Executing \"#{command}\"...".purple
        if options[:takeover]
          exec command # take over the process
        else
          system command
        end
      end
    end
  end
end

# require all files under lib
BrewGem.require_all_under(File.expand_path(File.dirname(__FILE__)))
