module VKontakte
  def self.getBtn(label : String, payload : Hash, color : String="default")
    {
      "action" => {
        "type" => "text",
        "payload" => payload.to_json,
        "label" => label
      },
      "color" => color
    }
  end
end
