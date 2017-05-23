### Known issues

* It is not possible to extract emails from Phabricator via API so they are generated based on username + email_domain option
* Language spec in code blocks (i.e. format=json) is not translated correctly to Gitlab notation it is just removed
* Newlines from maniphests are ignored so formatting of the messages could be messed up in some cases. Its default behavior of Gitlab
* Ordering (issue numbers) can be wrong for maniphests that have multiple project tags
* Duplicate issues are created for maniphests that have multiple project tags
