require 'pathname'
require 'rugged'
require 'nokogiri'
# require './svn.rb'

# PORT = Pathname.new(%x[which port].strip)
# $?.success? or raise "Could not locate MacPorts"

# PREFIX = PORT.parent.parent
# SOURCES = PREFIX + "etc/macports/sources.conf"

# PREFIX + "var/macports/sources/rsync.macports.org/release/tarballs/ports/"

# # def port_versions(portname)
# #   vers = %x[port list name:#{portname} | tr -s ' ' | cut -d ' ' -f 2].split
# #   #TODO: trap errors
# # end

REPOURL = "https://svn.macports.org/repository/macports/trunk/dports"

$portfiles = FileList[]
$min_rev = "1"

# def svn_base_rev
#   repo_url =  "https://svn.macports.org/repository/macports/trunk/dports"
#   ports = $portdirs.to_s
#   logres = %x[svn log -r 1:HEAD --limit 1 --xml #{repo_url} #{ports}]
#   return Nokogiri::XML(logres).xpath('string(/log/logentry/@revision)')
# end

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
  $portfiles.include("**/Portfile")
  $portdirs = $portfiles.pathmap("%d")
  puts $portdirs.join("\n") if ARGV.include?("list")
end

namespace :svn do

  desc "Find the oldest applicable revision"
  task :min_rev => :list do
    porturls = $portdirs.pathmap("#{REPOURL}/%p")

    info = %x[svn info --show-item last-changed-revision #{porturls} 2>/dev/null]
    exst_porturls = info.lines.map(&:split).map(&:last)

    exst_portdirs = $portdirs.dup().exclude do |dir|
      exst_porturls.none? {|url| url.end_with?(dir) }
    end

    logxml = %x[svn log -r 1:HEAD --limit 1 --xml #{REPOURL} #{exst_portdirs}]
    $min_rev = Nokogiri::XML(logxml).xpath('string(/log/logentry/@revision)')
    puts $min_rev
  end

  task :info => :list do
    porturls = $portdirs.pathmap("#{REPOURL}/%p")
    info = %x[svn info --show-item last-changed-revision #{porturls} 2>/dev/null]
    puts info
  end

  task :config do
    repo = Rugged::Repository.new('.')

    repo.config['svn-remote.macports.url'] =
      'https://svn.macports.org/repository/macports'

    repo.config['svn-remote.macports.fetch'] =
      'trunk/dports:refs/remotes/macports/trunk'
  end

  task :fetch do
    revs = $min_rev == "1" ? "" : "-r #{$min_rev}:HEAD"
    sh "git svn fetch macports #{revs}"
  end

  task :macports => [:config, :min_rev, :fetch] do
    repo.branches.create("macports-trunk", "macports/trunk")
  end

end

desc "Fetch the latest revisions from the MacPorts SVN repository"
task :fetch => 'svn:fetch'

desc "Checkout the specified portdir from the MacPorts branch"
task :checkout, :portdir do |t, args|
  portdir = args.portdir

  if Dir.exists?(portdir)
    fail "Portdir #{portdir} already exists"
  else
    sh "git checkout macports-trunk #{portdir}"
  end
end

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
