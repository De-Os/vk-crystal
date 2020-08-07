require "http"
require "json"

module VKontakte
  class LongPoll

    @server : String
    @key : String
    @ts : String
    @group_id : String
    @vk : VKontakte::Client

    def initialize(group_id, client : VKontakte::Client)
      @group_id, @vk = "#{group_id}", client

      lp = @vk.call("groups.getLongPollServer", {"group_id" => @group_id})
      @server, @key, @ts = lp["server"].as_s, lp["key"].as_s, lp["ts"].as_s
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

      if(updates["failed"]?)
        case updates["failed"].as_i
        when 1
          @ts = updates["ts"].as_s
        when 2
          @key = @vk.call("groups.getLongPollServer", {"group_id" => @group_id})["key"].as_s
        when 3
          lp = @vk.call("groups.getLongPollServer", {"group_id" => @group_id})
          @key, @ts = lp["key"].as_s, lp["ts"].as_s
        end
        return self.getUpdates
      else
        @ts = updates["ts"].as_s
        return updates["updates"]
      end
    end
  end
end
