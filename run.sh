#!/bin/bash

CURRENT_BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
JIRA_ISSUE_PATTERN='[A-Z]{2,7}-[0-9]{1,4}'
JIRA_ISSUE_NUMBER_PATTERN='[0-9]{1,4}'

for ARGUMENT in "$@"
do
  KEY=$(echo $ARGUMENT | cut -f1 -d=)
  VALUE=$(echo $ARGUMENT | cut -f2 -d=)

  case "$KEY" in
    COMMIT_EDITMSG_PATH)  COMMIT_EDITMSG_PATH="$(echo ${VALUE} | cut -d' ' -f1)";;
    AUTOINSERT)           AUTOINSERT=${VALUE};;
    ALLOWED_PREFIXES)     ALLOWED_PREFIXES=${VALUE};;
    *)
  esac
done

if [ -z "$COMMIT_EDITMSG_PATH" ]
then
  echo "ERROR: Missing argument COMMIT_EDITMSG_PATH."
  exit 1
fi

if [ ! -z "$AUTOINSERT" ] && [ $AUTOINSERT == 'true' ] && [ ! -z "$CURRENT_BRANCH_NAME" ] && [ "$CURRENT_BRANCH_NAME" != "HEAD" ]
then
  [[ $CURRENT_BRANCH_NAME =~ $JIRA_ISSUE_PATTERN ]]
  BRANCH_JIRA_ISSUE=${BASH_REMATCH[0]}

  if grep -E -q "$BRANCH_JIRA_ISSUE" $COMMIT_EDITMSG_PATH
  then
    echo "Jira issue already added to the commit message."
  else
    echo "Add jira issue to commit message..."
    sed -i.bak -e "1s~^~$BRANCH_JIRA_ISSUE ~" $COMMIT_EDITMSG_PATH
  fi
fi

if [ ! -z "$ALLOWED_PREFIXES" ]
then
  echo "Check only allowed jira issue exists in commit message..."
  IFS=',' read -ra ALLOWED_PREFIXES_ARRAY <<< "$ALLOWED_PREFIXES"
  for PREFIX in "${ALLOWED_PREFIXES_ARRAY[@]}"; do
    if grep -E -q "$PREFIX-$JIRA_ISSUE_NUMBER_PATTERN" $COMMIT_EDITMSG_PATH
    then
      echo "SUCCESS: Jira issue found."
      exit 0
    fi
  done
else
  echo "Check any jira issue exists in commit message..."
  if grep -E -q $JIRA_ISSUE_PATTERN $COMMIT_EDITMSG_PATH
  then
    echo "SUCCESS: Jira issue found."
    exit 0
  fi
fi

echo "ERROR: Jira issue not found."
exit 1
