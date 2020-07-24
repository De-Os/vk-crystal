require "json"
require "http"

module VKontakte
  class Client
    @token : String | Array(String)
    @v : String

    def initialize(token : String | Array(String), v : String)
      @token = token
      @v = v
    end

    def call(method : String, params : Hash, token : String | Array(String)=@token, debug : Bool=false)

      token = token.sample(1)[0] if token.is_a?(Array(String))

      response = JSON.parse(HTTP::Client.post(
        url: "https://api.vk.com/method/#{method}?access_token=#{token}&v=#{@v}",
        body: HTTP::Params.encode(params)
        ).body)
      if debug
        return response
      else
        return response["response"]
      end
    end

    def send(message : String, peer_id : Int32, attachments : Array(String)=[] of String)
      return self.call("messages.send", {
        "random_id" => "0",
        "peer_id" => peer_id.to_s,
        "attachment" => attachments.join(","),
        "message" => message.to_s
        })
    end

    def getName(user_id : Int32, name_case="Nom")
      if user_id < 0
        return "#{self.call("groups.get", {"group_ids" => "#{user_id}"})[0]["name"]}"
      else
        user = self.call("users.get", {"user_ids" => "#{user_id}", "name_case" => name_case})[0]
        return "#{user["first_name"]} #{user["last_name"]}"
      end
    end

    def upload(file_name : String, peer_id : Int32 | String)
      file_name = File.real_path(file_name)
      server = self.call("photos.getMessagesUploadServer", {"peer_id" => "#{peer_id}"})["upload_url"].as_s
      result = JSON::Any
      IO.pipe do |reader, writer|
        channel = Channel(String).new(1)
        spawn do
          HTTP::FormData.build(writer) do |formdata|
            channel.send(formdata.content_type)
            File.open(file_name) do |file|
              metadata = HTTP::FormData::FileMetadata.new(filename: file_name)
              headers = HTTP::Headers{"Content-Type" => "image"}
              formdata.file("photo", file, metadata, headers)
            end
          end
          writer.close
        end
        response = HTTP::Client.post(server,
          body: reader,
          headers: HTTP::Headers{"Content-Type" => channel.receive}
        )
        result = JSON.parse(response.body)
        result = self.call("photos.saveMessagesPhoto", {
          "server" => "#{result["server"]}",
          "hash" => "#{result["hash"].as_s}",
          "photo" => "#{result["photo"].as_s}"
          })[0]
        return "photo#{result["owner_id"]}_#{result["id"]}"
      end
    end
  end
end
