['IMAGE_DIR','IMAGER_USER','IMAGER_HOST'].each do |env_variable|
  raise "ENV['#{env_variable}'] is not set!" if ENV[env_variable].nil?
end

# export IMAGE_DIR=/Volumes/DeployStudio/Masters/HFS
# export IMAGER_USER=pivotal
# export IMAGER_HOST=bacon
# export DEPLOYSTUDIO_SSH_KEYFILE=/Users/pivotal/.ssh/id_union_deploy
# export DEPLOYSTUDIO_DESTDIR=/Volumes/PivotLand/DeployStudio/Masters/HFS
# export DEPLOYSTUDIO_USER_HOST=deploy@union

require 'timeout'

module Util
  def on_persistent?
    # sometimes the disks aren't mounted; mount both disks to make sure
    system("ssh #{ENV['IMAGER_USER']}@#{ENV['IMAGER_HOST']} -o ConnectTimeout=5 'sudo hdid #{persistent_partition}; sudo hdid #{newly_imaged_partition}; df' | egrep '/Volumes/NEWLY_IMAGED|/Volumes/Persistent'")
  end

  def reboot_to(volume)
    puts("rebooting to #{volume}")
    system("ssh #{ENV['IMAGER_USER']}@#{ENV['IMAGER_HOST']} 'sudo hdiutil attach /dev/disk0'")
    puts("Blessing #{volume}")
    system("ssh #{ENV['IMAGER_USER']}@#{ENV['IMAGER_HOST']} 'sudo bless --mount #{volume} --setboot'")
    puts("shutting down")
    system("ssh #{ENV['IMAGER_USER']}@#{ENV['IMAGER_HOST']} 'sudo shutdown -r now'")
  end

  def disappear_reappear
    # wait for machine to disappear
    Timeout::timeout(120) do
      if system("ssh #{ENV['IMAGER_USER']}@#{ENV['IMAGER_HOST']} -o ConnectTimeout=5 'true'")
        sleep 1
      end
    end

    puts "machine down"

    # wait for machine to reappear
    Timeout::timeout(120) do
      until system("ssh #{ENV['IMAGER_USER']}@#{ENV['IMAGER_HOST']} -o ConnectTimeout=5 'true'")
        sleep 1
      end
    end

  end

  def system!(cmd)
    if ! system(cmd)
      raise "#{cmd}: #{$?.exitstatus}"
    end
  end
end

