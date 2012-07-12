#!/bin/bash
set -e

ssh $IMAGER_USER@$IMAGER_HOST 'mkdir -p ~/cookbooks; mkdir -p ~/workspace'
ssh $IMAGER_USER@$IMAGER_HOST 'cd cookbooks &&
  git clone https://github.com/pivotal/pivotal_workstation.git && 
  cd ~/workspace &&
  git clone https://github.com/pivotalexperimental/apple_orchard.git'


ssh $IMAGER_USER@$IMAGER_HOST 'cat > soloistrc <<EOF
cookbook_paths:
- cookbooks
recipes:
- pivotal_workstation::meta_osx_base
- pivotal_workstation::meta_osx_development
- pivotal_workstation::meta_ruby_development
- pivotal_workstation::function_keys
- pivotal_workstation::flycut
EOF
'

if [[ $PIVOTAL_LABS ]]; then
  ssh $IMAGER_USER@$IMAGER_HOST 'eval `ssh-agent` && 
    ssh-add  ~/.ssh/id_github_lion && 
    ( ssh -o StrictHostKeyChecking=no git@github.com ls; pushd cookbooks ) && 
    git clone git@github.com:pivotalprivate/pivotal_workstation_private.git && 
    pushd pivotal_workstation_private &&
    git remote set-url origin https://pivotalcommon@github.com/pivotalprivate/pivotal_workstation_private.git &&
    popd && popd &&
    echo "- pivotal_workstation::meta_pivotal_specifics" >> ~/soloistrc &&
    echo "- pivotal_workstation_private::meta_lion_image >> ~/soloistrc "'
fi

ssh $IMAGER_USER@$IMAGER_HOST 'gem list | grep chef || sudo gem install chef --version 0.10.8'
ssh $IMAGER_USER@$IMAGER_HOST 'gem list | grep soloist || sudo gem install soloist'
ssh $IMAGER_USER@$IMAGER_HOST 'soloist'

# post-install, set the machine name to NEWLY_IMAGED
ssh $IMAGER_USER@$IMAGER_HOST 'sudo hostname NEWLY_IMAGED
  sudo scutil --set ComputerName   NEWLY_IMAGED
  sudo scutil --set LocalHostName  NEWLY_IMAGED
  sudo scutil --set HostName       NEWLY_IMAGED
  sudo diskutil rename /           NEWLY_IMAGED'

ssh $IMAGER_USER@$IMAGER_HOST 'sudo cp ~/workspace/apple_orchard/assets/com.pivotallabs.auto_set_hostname.plist  /Library/LaunchAgents/'
ssh $IMAGER_USER@$IMAGER_HOST 'mkdir ~/bin; sudo cp ~/workspace/apple_orchard/assets/auto_set_hostname.rb /usr/sbin/'

ssh $IMAGER_USER@$IMAGER_HOST 'sudo bless --mount /Volumes/Persistent --setboot'
ssh $IMAGER_USER@$IMAGER_HOST 'rm -fr ~/.ssh; sudo shutdown -r now'
