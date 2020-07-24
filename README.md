# vk-crystal
Библиотека для взаимодействия с vk.com из под Crystal

## Установка
Добавьте данные строчки в `shards.yml` Вашего проекта:
```crystal
dependencies:
  vk:
    github: De-Os/vk-crystal  
```

## Использование

Первым делом добавляем `require` и инициализируем класс
```crystal
require "vk"

vk = VKontakte::Client.new(
  token: "Ваш токен",
  v: "Версия апи"
)
```
Также в качестве токена можно использовать массив с несколькими токенами, тогда при запросах будет использоваться случайный

### Вызов любого метода

Используется функция `call` с названием метода в качестве первого аргумента и Hash(String, Any) с параметрами в качестве второго:
```crystal
friends = vk.call("friends.get", {
    "user_id" => 0,
    "count" => 1000
  })
# typeof(friends) => JSON::Any
```
По умолчанию возвращается сразу графа `response`, но при указании параметра `debug: true` будет возвращён весь ответ

Также, можно указать параметр `token: "token"`, тогда вызов будет осуществлён через указанный токен

## Отправка сообщения

Для отправки сообщения существует отдельный метод `send`:
```crystal
vk.send("Test message", peer_id) # peer_id - ид чата
```
### Загрузка и отправка вложений
На данный момент поддерживается только загрузка фотографий через метод `upload`:
```crystal
photo = vk.upload("cat.png") # => photo123_456
```
Для указания `peer_id` добавьте его вторым параметром:
```crystal
vk.upload("cat.png", 123)
```
Для отправки сообщения со вложением воспользуйтесь вызовом `send` с трёмя параметрами:
```crystal
vk.send("Nice cat!", peer_id, photo)
# Либо несколько вложений:
vk.send("Nice cats!", peer_id, [vk.upload("cat1.png", peer_id), vk.upload("cat2.png", peer_id)])
```

## Остальные реализованные методы:
#### Получение имени пользователя/группы:
```crystal
name = vk.getName(user_id) # => "Имя Фамилия" или "Название группы"
# также можно получать с указанием падежа
name = vk.getName(user_id, "Ins") # Игнорируется при получении имени группы
```

## Bot's LongPoll
В модуле присутствует примитивный лонгполл, с помощью которого можно строить ботов. Пример простейшего бота с данным модулем:
```crystal
# Создание и подключение
lp = vk.call("groups.getLongPollServer", {"group_id" => 123})
lp = VK::LongPoll.new(lp["server"].as_s, lp["key"].as_s, lp["ts"].as_s)

# Обработка событий
loop do
  updates = lp.getUpdates

  size = 0 # JSON::Any не имеет функции 'each', поэтому приходится так
  while size < updates.size
    update = updates[size] # Конкретное обновление

    case update["type"].as_s
    when "message_new"
      vk.send("Не пиши сюда >:(", update["object"]["message"]["peer_id"].as_i)
    end
  end
end
```
