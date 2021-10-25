# EasyGit

This bash script is intended for users who are completely unfamiliar with git.
It does not use git terms concepts, like branches, commits, etc.
Instead, the user deals with "tasks", which are actually branches.

## Requirements

* Git
* Git Bash
* Git repository

## Languages

* Russian

## Features

* User can check if there are unsaved changes (option [1])
* Changes on master are not allowed
* Unsaved changes can be moved to other branches
* User can start working on a new task after having saved the current changes (option [2])
* User can switch to other task after having saved the current changes (option [3])
* Changes are saved by staging, committing and pushing a branch to the remote, all in one operation (option [4]|)
* User can complete the task and switch to master (option [5])

## How to use

1. Copy ``work.sh`` to your repository.
1. Launch the script.
You can keep the script running while working with the repository. 
1. Follow the instructions.
1. Re-launch the script if it stops working for any reason.
