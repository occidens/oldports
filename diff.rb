#!/usr/bin/env ruby

require 'rugged'

path, oldfile, oldsha, oldmode,
newfile, newsha, newmode = ARGV

TIME_FMT = "%F %T.%N %z"

def find_commit_of_blob(repo, wanted, earliest=true)
  walker = Rugged::Walker.new(repo)

  walker.sorting(
    Rugged::SORT_DATE | (earliest ? Rugged::SORT_REVERSE : Rugged::SORT_NONE))

  repo.references.each do |ref|
    walker.push(ref.target)
  end

  walker.find do |c|
    c.tree.walk(:preorder).find do |rt, e|
      e[:oid] == wanted
    end
  end
end

def label(repo, path, sha)
  time="???"

  if sha == "." then
    path = "/dev/null"
    time = Time.now.strftime(TIME_FMT)
  else
    commit = find_commit_of_blob(repo, sha)
    if commit
      time = commit.time.strftime(TIME_FMT)
    end
  end
   return "#{path}\t#{time}"
end

repo = Rugged::Repository.discover(".")

oldlabel = label(repo, path, oldsha)
newlabel = label(repo, path, newsha)

puts %x[diff -u --label "#{oldlabel}" --label "#{newlabel}" "#{oldfile}" "#{newfile}"]

($?.exitstatus < 2) ? exit(0) : exit(1)
