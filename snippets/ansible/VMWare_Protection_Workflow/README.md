#### Executing the snippets in ansible

This is an end to end workflow.   Assuming an inventory files holds vcenter info and a task file holds the specifics for the policy templates

inventory:
  -- Holds inventory info


tasks:
-name: name of tasks
  include_task: tasklocation/taskname

  Tasks are calling tasks to create a workflow for tags and folder support design.


Vars for ansible are defined in a inventory file for use in plays
vars created during plays are used in future ones like login.yml.
