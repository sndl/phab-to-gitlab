require 'gitlab'

class Gitlab::Client
  def create_issue_note(project, issue, body, author, created_at)
    post("/projects/#{url_encode project}/issues/#{issue}/notes?private_token=#{@private_token}&sudo=#{author}",
         body: { body: body, created_at: created_at }
        )
  end

  def create_issue(project, title, author, options={})
    body = { title: title }.merge(options)
    post("/projects/#{url_encode project}/issues?private_token=#{@private_token}&sudo=#{author}", body: body)
  end
end
