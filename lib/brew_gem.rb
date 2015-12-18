require 'erb'
require 'tempfile'

module BrewGem
  class << self
    def install(name, version, options = {})
      perform(:install, name, version, options)
    end

    def update(name)
      perform(:update, name)
    end

    def uninstall(name)
      perform(:uninstall, name)
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
    def perform(command, name = nil, version = nil, options = {})
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

          gem_name = `ls #{File.join(local_path, '*')}.gem`.chomp

          # recursively call self to install from local gem
          run "#{$0} install --local=#{gem_name}", takeover: true
        end
      elsif options[:github]
        # clone from github and build gem
        github_gem_path = options[:github]
        name = github_gem_path.match(/.*\/(.*)\.git$/)[1]
        target_dir_name = File.join(Dir.tmpdir, "build-#{name}-#{rand(100000000)}")
        run "git clone #{github_gem_path} #{target_dir_name}"
        # recursively call self to install from local dir
        run "#{$0} install --local=#{target_dir_name}", takeover: true
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

        system "brew #{command} #{filename}"
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
        puts "Executing \"#{command}\"..."
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
