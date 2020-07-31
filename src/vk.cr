require "json"
require "http"
require "./**"

module VKontakte

  alias KeyboardType = String | Hash(String, String | Array(Hash(String, String | Hash(String, String))))

  class Client

    @token : String | Array(String)
    @v : String

    def initialize(token : String | Array(String), v : String)
      @token = token
      @v = v
    end

    def call(method : String, params : Hash, token : String | Array(String)=@token, debug : Bool=false)

      token = token.sample(1)[0] if token.is_a?(Array(String))

      if !params.is_a?(Hash(String, String))
        temp = {} of String => String
        params.each do |key, value|
          temp[key] = "#{value}" if !value.is_a?(String)
        end
        params = temp
      end

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

    def send(message : String, peer_id : Int32, attachments : String | Array(String)=[] of String, keyboard={} of String => VKontakte::KeyboardType, add_fields={} of String => String)
      attachments = [attachments] if attachments.is_a?(String)
      add_fields["keyboard"] = keyboard.to_json if keyboard.size > 0
      return self.call("messages.send", {
        "random_id" => "0",
        "peer_id" => peer_id.to_s,
        "attachment" => attachments.join(","),
        "message" => message.to_s
      }.merge!(add_fields))
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

    def getBtn(label : String, payload : Hash, color : String="default")
      VKontakte.getBtn(label, payload, color)
    end

    def getBotLp(group_id) : VKontakte::LongPoll
      lp = self.call("groups.getLongPollServer", {"group_id" => group_id})
      VKontakte::LongPoll.new(lp["server"].as_s, lp["key"].as_s, lp["ts"].as_s)
    end
  end
end
