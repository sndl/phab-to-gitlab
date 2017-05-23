### Setup

1. Run `bundler install`
2. Configure your `config.yml` based on `config.yml.example`

### Migrate Users

To migrate users:
1. Run `./migrate.rb user`

### Migrate Tickets

To migrate tickets:
1. Ensure that all required users have admin rights in gitlab
2. Configure correct mapping in `mapping.yml`
3. Run `./migrate.rb ticket`
4. When the process is finished there will be `uploads` directory, its content need to be uploaded to your gitlab server with correct permissions

### Known issues

* It is not possible to extract emails from Phabricator via API so they are generated based on username + email_domain option
* Language spec in code blocks (i.e. format=json) is not translated correctly to Gitlab notation it is just removed
* Newlines from maniphests are ignored so formatting of the messages could be messed up in some cases. Its default behavior of Gitlab
* Ordering (issue numbers) can be wrong for maniphests that have multiple project tags
* Duplicate issues are created for maniphests that have multiple project tags
