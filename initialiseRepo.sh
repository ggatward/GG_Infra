#!/bin/bash

#rm -rf collections/ansible_collections/*
#ansible-galaxy collection install -r collections/requirements.yml -f

# Refresh galaxy roles
rm -rf roles/galaxy/*
ansible-galaxy install -r roles/requirements.yml -f
