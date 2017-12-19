
# when initilizing a variable, there cannot have spaces between = .
token=$(cat /tmp/fbToken)
if [ $? -ne 0 ]; then
  echo Generating new API token...
  content=$(curl -s https://lpqopm.loanspq.com/api.asp?cmd=logon\&email=???\&password=???)
  echo "$content" | grep -oP \(?\<=CDATA\\[\).+?\(?\=\\]\) > /tmp/fbToken

  token=$(cat /tmp/fbToken)
fi

echo Your API token is "$token"

currentBranch=$(git branch | grep -oP \(?\<=\\*\\s\)[[:digit:]]\{4,\}.*)
if [ -z $currentBranch ]; then
	echo You are not on a case branch.
	exit 1
elif echo $currentBranch |  grep -oP [[:digit:]]\{4,\}[^[:digit:]] ; then # semicolon is used to separate keywords as elif and then are keywords.
	echo The branch already has a description.
	exit 2
fi

caseId=$currentBranch




content=$(curl -s https://lpqopm.loanspq.com/api.asp?cmd=search\&q=$caseId\&cols=sTitle\&token=$token)
title=$(echo "$content" | grep -oP \(?\<=CDATA\\[\).+?\(?\=\\]\) )


title="${title%"${title##*[![:space:]]}"}"  # remove tailing whitespace
title=$(echo "$title" | sed 's/\(\w\)\(\w*\)/\u\1\L\2/g') # change title to CamelCase
echo $title

description=""
description=$description

while [ ${#description} -le 15 ]; do
	title="${title#"${title%%[![:space:]]*}"}" # remove leading whitespace

	match=$( echo "$title" | grep -oP ^\\w\+ )
	description=$description$match
	title=$( echo "$title" | cut -c$((${#match}+2))- )
done

if [ -z "$description" ]; then
	echo Unable to get case description.
	exit 3
fi

echo short title is "$description"

git branch -m "$currentBranch" "$currentBranch$description"
