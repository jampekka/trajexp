#!/bin/bash

pushd trusas0
make nexus
popd

pushd webtrajsim
npm install
popd
