SOURCES = "/opt/local/etc/macports/sources.conf"
require 'rugged'

file ".git/hooks/post-commit" do |t|
  File.open(t.name, "w") { |f| f.puts "rake PortIndex" }
  sh "chmod +x #{t.name}"
end

desc "Rebuild the Port index."
file "PortIndex" => Dir["**/Portfile"] do
  sh "portindex"
end

desc "List local ports."
task :list do
  puts Dir["**/Portfile"]. map { |f| File.dirname f }.join("\n")
end

desc "Set up git-svn remote and fetch MacPorts trunk"
task :macports do
  baserev = "146722"
  repo = Rugged::Repository.new('.')

  repo.config['svn-remote.macports.url'] =
    'https://svn.macports.org/repository/macports'

  repo.config['svn-remote.macports.fetch'] =
    'trunk/dports:refs/remotes/macports/trunk'

  sh "git svn fetch macports -r #{baserev}:HEAD"
  repo.branches.create("macports-trunk", "macports/trunk")
end

desc "Install source and post-commit hook, build Port index."
task :setup => %w(.git/hooks/post-commit PortIndex) do
  us      = "file://#{File.expand_path '.'}/"
  sources = IO.read SOURCES

  unless sources.include? us
    lines = sources.split "\n"

    lines.each_with_index do |line, index|
      if line =~ /^[a-z]/i
        lines.insert index, us
        break
      end
    end

    tmp = "/tmp/sources.conf.tmp"
    File.open(tmp, "w") { |f| f.puts lines.join("\n") }

    prompt = "Sudo password to update macports sources:"
    sh "sudo -p '#{prompt} ' mv #{tmp} #{SOURCES}"
  end
end

task :default => :setup
