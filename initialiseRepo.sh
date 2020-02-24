#!/bin/bash


# Refresh galaxy roles
rm -rf roles/galaxy/*
ansible-galaxy install -r roles/requirements.yml -f
