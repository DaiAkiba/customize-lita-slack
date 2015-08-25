# asl-develop-lita
slack bot for asl-develop

# Paramaters
export SLACK_API_KEY="xxxxxx"<br>
export LITA_SLACK_KEY="xxxxxx"

# Getting Started
```
$ bundle install vendor/bundle
$ bundle exec lita start
```

# Slack Commands
* **getfl**<br>
[_summary_] Get file list<br>
[_options_]<br>
-d : Set EndDate to Read.(Format:YYYYMMDD)<br>
-u : Set File Owner to Read.

* **delfl**<br>
[_summary_] Delete files<br>
[_options_]<br>
-d : Set EndDate to Delete.(Format:YYYYMMDD)<br>
-u : Set File Owner to Delete.
