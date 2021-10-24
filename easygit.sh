#/bin/bash
function checkStatus {
   printf "\nПроверка статуса...\n\n"
   # Getting the current git status
   git fetch origin
   branch=$(git branch --show-current)
   printf "Текущая задача: $branch\n"
   status=$(git status)
   # Case if user is on master and has made changes (which is restricted)
   if [[ ($status =~ "On branch master") && ($status =~ "untracked files present" || $status =~ "new file:" || $status =~ "deleted:" || $status =~ "Untracked files:" || $status =~ "modified:" || $status =~ "branch is ahead of" || $status =~ "Changes to be committed:") ]]; then
      option=0
      while [[ ($option != 1) && ($option != 2) && ($option != 3) && ($option != 'q') ]]; do
         printf "Вы внесли изменения вне задачи. Выберите действие:\n[1] Удалить изменения\n[2] Перенести в существующую задачу\n[3] Перенести в новую задачу\n[q] Вернуться в главное меню\n"
         read option
      done
      case $option in
         1) git clean -fd && git reset --hard origin/master;;
         2) stashToExisting && return 12;;
         3) stashToNew && return 12;;
         q) printf "Для продолжения работы необходимо удалить изменения.\nВозврат в главное меню..." && return 12;;
      esac
   fi
   # Case if there are untracked, modified or uncommited changes
   if [[ $status =~ "untracked files present" || $status =~ "new file:" || $status =~ "deleted:" || $status =~ "Untracked files:" || $status =~ "modified:" || $status =~ "branch is ahead of" || $status =~ "Changes to be committed:" ]]; then
      option=0
      while [[ ($option != 1) && ($option != 2) && ($option != 3) && ($option != 4) && ($option != 'q') ]]; do
         printf "В текущей задаче есть несохраненные изменения. Выберите действие:\n[1] Сохранить изменения\n[2] Перенести в существующую задачу\n[3] Перенести в новую задачу\n[4] Удалить изменения\n[q] В главное меню\n"
         read option
      done
      case $option in
         1) saveWork && return;;
         2) stashToExisting && return 12;;
         3) stashToNew && return 12;;
         4) git clean -fd && git reset --hard;;
         q) printf "\nИзменения не сохранены.\nВозврат в главное меню...\n" && return 12;;
      esac
   fi
   # Case if nothing to commit and no changes
   if [[ $status =~ "nothing to commit, working tree clean" ]]; then
      printf "Несохраненных изменений нет\n"
      return
   fi
}

function startTask {
   # Creating a new branch for the task
   printf "Введите номер задачи в Jira:\n"
   read task
   option=0
   while [[ ($option != 'y') && ($option != 'n') ]]; do
      printf "Хотите начать работу над задачей $task? (y/n)\n"
      read option
   done
   if [ $option = "y" ]; then
      checkStatus
      status=$?
      if [ $status = "12" ]; then
         printf "\nНе удалось начать работу...\n"
         return
      fi
      git checkout master
      git pull origin master
      git checkout -b $task
      status=$(git status)
      # Case if the branch already exists
      if [[ $status != *$task* ]]; then
         printf "\nНе удалось создать задачу. Проверьте название, либо выберите 'Переключиться в главном меню'\nВозврат в главное меню...\n"
         return
      fi
      # Case if successfully created and switched to the branch
      if [[ $status =~ $task ]]; then
         printf "\nМожно начинать работу над задачей $task\n"
         return
      fi
   fi
   if [ $option = "n" ]; then
      printf "\nВозврат в главное меню...\n"
      return
   fi
}

function saveWork {
   # Saving changes (redirect to check status function)
   checkMaster
   status=$?
   if [ $status = "12" ]; then
      return
   fi 
   # Getting the current branch name
   branch=$(git branch --show-current)
   msg_len=0
   # Case if nothing to commit and no changes
   status=$(git status)
   if [[ $status =~ "nothing to commit, working tree clean" ]]; then
      printf "Несохраненных изменений нет\n"
      return
   fi
   # Getting the commit message
   while [[ (msg_len -le 4) || (msg_len -gt 50) ]]; do
      printf "Введите краткое описание внесенных изменений на английском (5-50 символов):\n"
      read msg
      msg_len=${#msg}
   done
   # Staging, committing and pushing
   git add -A
   git commit -m "$msg"
   git push origin $branch
   printf "\n\nИзменения внесены\n"
   return
}

function finishWork {
   # Finishing work (redirect to check status function + returning to master branch)
   checkMaster
   status=$?
   if [ $status = "12" ]; then
      return
   fi 
   checkStatus
   status=$?
   if [ $status = "12" ]; then
      printf "\nНельзя завершать работу над задачей при несохраненных изменениях"
      return
   fi
   git checkout master
   git pull origin master
   printf "\n\nРабота завершена. Сообщите администратору о завершении работы над задачей $branch\n"
}

function checkMaster {
   # Checking if the user is on master
   branch=$(git branch --show-current)
   if [ $branch = "master" ]; then
      printf "Вы не можете сохранять изменения вне задачи\n"
      return 12
   fi
}

function continueTask {
   # Switching to an existing branch to continue work
   # Checking if there are current changes
   checkStatus
   status=$?
   if [ $status = "12" ]; then
      printf "\nНельзя переключиться на другую задачу при несохраненных изменениях"
      return
   fi
   printf "\nВведите номер задачи в Jira:\n"
   read task
   git checkout $task
   # Case if the branch does not exist
   status=$(git status)
   if [[ $status != *$task* ]]; then
      printf "\nЗадача не найдена. Проверьте название, либо выберите 'Начать работу' в главном меню.\nВозврат в главное меню...\n"
      return
   fi
   # Case if successfully switched to the branch
   if [[ $status =~ $task ]]; then
      printf "\nМожно продолжать работу над задачей $task\n"
   fi
}

function stashToExisting {
   git stash -u
   printf "\nВведите номер задачи в Jira:\n"
   read task
   git checkout $task
   # Case if the branch does not exist
   status=$(git status)
   if [[ $status != *$task* ]]; then
      git stash pop
      printf "\nЗадача не найдена. Проверьте название, либо выберите 'Перенести в новую задачу'.\nВозврат в главное меню...\n"
      return
   fi
   # Case if successfully switched to the branch
   if [[ $status =~ $task ]]; then
      git stash pop
      printf "\nИзменения перенесены в задачу $task"
   fi
}

function stashToNew {
   git stash -u
   printf "\nВведите номер задачи в Jira:\n"
   read task
   git checkout -b $task
   # Case if the branch already exists
   status=$(git status)
   if [[ $status != *$task* ]]; then
      git stash pop
      printf "\nНе удалось создать задачу. Проверьте название, либо выберите 'Перенести в существующую задачу'\nВозврат в главное меню...\n"
      return
   fi
   # Case if successfully created and switched to the branch
   if [[ $status =~ $task ]]; then
      git stash pop
      printf "\nИзменения перенесены в новую задачу $task"
      return
   fi
}

# Main menu
# Checking status on startup
checkStatus
option=0
while [[ ($option -ne 1) && ($option -ne 2) && ($option -ne 3) && ($option -ne 4) && ($option -ne 5) && ($option != 'q') ]]
do
printf "\nВыберите действие:\n[1] Проверить статус \n[2] Начать работу\n[3] Переключиться\n[4] Сохранить работу\n[5] Завершить работу\n[q] Выход\n"
read option

case $option in
   1) checkStatus && option=0;;
   2) startTask && option=0;;
   3) continueTask && option=0;;
   4) saveWork && option=0;;
   5) finishWork && option=0;;
   q) printf "Выход..." && exit 1;;
esac


done