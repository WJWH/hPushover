hPushover
=========

Haskell bindings to the Pushover.net service.

=========

Use this library to send push messages to any Android or Apple device that has the Pushover app installed. Also see the haddock generated documentation in the /dist/doc folder.

Example:
```
{-# LANGUAGE OverloadedStrings #-}
import Saas.Pushover

myMessage = defaultMessage { token = "my_App_token", user = "my_user_key", message = "Hello world!"}

main = withSocketsDo $ sendPushMessage myMessage 
```

=========
To install, use *cabal update && cabal install hpushover*. 
Please do not hesitate to contact me with questions, feature request or issue reports!
