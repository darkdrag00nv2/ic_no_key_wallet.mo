#!/usr/bin/env bash

./local.sh

cd test/e2e && npm run test

dfx stop
