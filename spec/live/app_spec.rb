require 'core/spec_helper'

describe ZendeskAPI::App do
  it "should work "do
    upload = VCR.use_cassette("app_upload_create") do
      ZendeskAPI::App::Upload.new(client, :id => "spec/fixtures/sample_app.zip").tap(&:save!)
    end

    attributes = { :upload_id => upload.id, :name => "My App", :short_description => "Testing" }

    app = ZendeskAPI::App.new(client, attributes)

    VCR.use_cassette("app_create") { app.save! }

    body = {}

    VCR.use_cassette("app_create_job_status") do
      until %w{failed completed}.include?(body["status"])
        response = client.connection.get(app.response.headers["Location"])
        body = response.body

        sleep(3)
      end
    end

    if body["status"] == "failed"
      fail "Could not create app: #{body.inspect}"
    end

    app.id = body["app_id"]
    app.short_description = "My Test App"

    VCR.use_cassette("app_save") { app.save! }

    app.short_description.should == "My Test App"
    app.author_name.should == "Skip Moore"

    VCR.use_cassette("app_destroy") { app.destroy! }
  end
end
