### NetBackup API Code Samples for Ansible

This directory contains code samples to invoke NetBackup REST APIs using ansible.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- NetBackup 8.1.1 or higher
- ansible 2.x


#### Executing the snippets in ansible

These are tasks meant to be part of a larger playbook.   I use them with the following syntax

tasks:
-name: name of tasks
  include_task: tasklocation/taskname


Vars for ansible are defined in a inventory file for use in plays
vars created during plays are used in future ones like login.yml.
