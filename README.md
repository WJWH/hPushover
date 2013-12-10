hPushover
=========

Haskell bindings to the Pushover.net service.

=========

Using this library you can send push messages to any Android or Apple device that has the Pushover app installed.

Example:
```
{-# LANGUAGE OverloadedStrings #-}
import Saas.Pushover

myMessage = defaultMessage { token = "my_App_token", user = "my_user_key", message = "Hello world!"}

main = withSocketsDo $ sendPushMessage myMessage 
```

=========

Please do not hesitate to contact me with questions, feature request or issue reports!
