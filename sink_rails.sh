#!/bin/sh -x
CURRENT=`git branch | grep "*" | awk '{print $2}'`
git checkout deploy-test
git pull origin deploy-test
git checkout ${CURRENT}
git rebase deploy-test ${CURRENT}
