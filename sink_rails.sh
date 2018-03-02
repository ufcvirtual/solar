#!/bin/sh -x
CURRENT=`git branch | grep "*" | awk '{print $2}'`
git checkout rails_4_1_8
git pull origin rails_4_1_8
git checkout ${CURRENT}
git rebase rails_4_1_8 ${CURRENT}
