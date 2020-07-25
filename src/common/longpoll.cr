require "http"
require "json"

module VKontakte
  class LongPoll

    @server : String
    @key : String
    @ts : String

    def initialize(server : String, key : String, ts : String | Number)
      ts = "#{ts}" if !ts.is_a?(String)

      @server, @key, @ts = server, key, ts
    end

    def getUpdates
      updates = JSON.parse(HTTP::Client.get(
        url: "#{@server}?#{HTTP::Params.encode({
          "act" => "a_check",
          "key" => @key,
          "wait" => "5",
          "version" => "3",
          "ts" => @ts
        })}"
      ).body)
      if updates["updates"]?
        @ts = updates["ts"].as_s
        return updates["updates"]
      end
    end
  end
end
