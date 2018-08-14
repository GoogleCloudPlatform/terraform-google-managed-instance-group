#!/usr/bin/env bash

fly -t tf set-pipeline -p tf-mig-regression -c tests/pipelines/tf-mig-regression.yaml -l tests/pipelines/values.yaml

fly -t tf expose-pipeline -p tf-mig-regression