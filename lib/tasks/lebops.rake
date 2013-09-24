desc "Reset TocTicket DataBase"
namespace :db do
  task :reset do
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
    Rake::Task['db:seed'].invoke
  end
end

desc "Version control"
namespace :version do
  CLIENT_REMOTE = "client_remote"

  desc "Create/Rewrite Client remote repo: rake version:client_remote[repo]"
  task :client_remote, :repo do  |t, args|
    repo = args[:repo]
    sh "git remote add #{CLIENT_REMOTE} #{repo}" do |ok, res|
      if ! ok
        sh "git remote remove #{CLIENT_REMOTE}"
        sh "git remote add #{CLIENT_REMOTE} #{repo}"
      end
    end
  end

  desc "Release a version: rake version:release[version_number]"
  task :release, :number do  |t, args|
    version_number = args[:number]
    check_for_number(version_number)
    sh "git remote show #{CLIENT_REMOTE}" do |ok, res|
      if ! ok
        puts "Please, create Client remote repo: rake version:client_remote[repo]"
        raise
      end
    end
    # Synchronize remotes
    sh "git push origin master"
    sh "git push #{CLIENT_REMOTE} master"
    # Tagging
    sh "git tag -a v#{version_number} -m 'Version #{version_number} - #{Time.now.to_date}'"
    sh "git push origin --tags"
    sh "git push #{CLIENT_REMOTE} --tags"
  end

  desc "Delete a version: rake version:remove[version_number]"
  task :remove, :number do  |t, args|
    version_number = args[:number]
    check_for_number(version_number)
    sh "git tag -d v#{version_number}"
    sh "git push origin :refs/tags/v#{version_number}"
    sh "git push #{CLIENT_REMOTE} :refs/tags/v#{version_number}"
  end

  def check_for_number(version_number)
    if version_number.nil?
      puts "We need a version number: [version_number] !!"
      raise
    end
  end

end