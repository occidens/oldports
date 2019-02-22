require 'pathname'
require 'rugged'
require 'nokogiri'

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
REPOREF = "refs/remotes/macports/trunk"
REPO_TRACK_BRANCH = "macports-trunk"

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

namespace :git do
  task :repo do
    $repo = Rugged::Repository.new('.')
  end
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

  task :config => 'git:repo' do
    $repo.config['svn-remote.macports.url'] =
      "https://svn.macports.org/repository/macports"

    $repo.config['svn-remote.macports.fetch'] =
      "trunk/dports:#{REPOREF}"
  end

  task :fetch => 'git:repo' do
    revs = $min_rev == "1" ? "" : "-r #{$min_rev}:HEAD"
    sh "git svn fetch macports #{revs}"

    remote_sha = $repo.references[REPOREF].target.oid
    local_ref = $repo.branches[REPO_TRACK_BRANCH].canonical_name
    $repo.references.update(local_ref, remote_sha)

    puts "Updated #{REPO_TRACK_BRANCH}"
  end

  task :macports => [:config, :min_rev, :fetch] do
    $repo.branches.create(REPO_TRACK_BRANCH, "macports/trunk")
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

def diff(sources, outfile=nil)
  cmd = "git diff macports-trunk..HEAD -- #{sources}" +
        ( outfile ? " | tee #{outfile}" : "" )
  ENV["GIT_EXTERNAL_DIFF"]="./diff.rb"
  sh cmd
end

desc "Diff against MacPorts trunk"
task :diff, [:path] => 'svn:fetch' do |t, args|
  inpaths = FileList[args[:path]].include(args.extras)

  outfiles = Rake.application.top_level_tasks.grep(/^.*\.diff$/)
  num_outfiles = outfiles.length

  $diff_sources = {}

  if num_outfiles == 0
    diff inpaths

  elsif num_outfiles > inpaths.length
    raise "Too many output files specified"

  else
    inpaths.zip(outfiles) do |ip, of|
      entry = { of || outfiles.last => [ip] }
      puts entry
      $diff_sources.update(entry) do |_, old, new|
        old + new
      end
    end
    puts $diff_sources
  end
end

DIFF_PREREQ = proc do |outfile|
  $diff_sources[outfile]
end

rule ".diff" => DIFF_PREREQ do |t|
  diff FileList[t.sources], t.name
end

task :check do
  Rake.application.top_level_tasks.each { |t| puts t.class }
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
