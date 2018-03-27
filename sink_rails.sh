#!/bin/sh -x
CURRENT=`git branch | grep "*" | awk '{print $2}'`
git checkout rails_4_0_0
git pull origin rails_4_0_0
git checkout ${CURRENT}
git rebase development ${CURRENT}
