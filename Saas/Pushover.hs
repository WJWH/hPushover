{-# LANGUAGE OverloadedStrings #-}

-- |Small library that provides functions to send push messages to Android and Apple devices which have the Pushover app installed. Please note that the
-- IO function make use of the network stack and should be wrapped with @withSocketsDo@.
module Saas.Pushover (
    -- *Data types
    PushMessage(..),
    PushResponse(..),
    ReceiptResponse(..),
    Apptoken,
    Receipt,
    -- *Default constructor
    defaultMessage,
    -- *IO functions
    sendPushMessage,
    checkReceipt
    ) where

import Control.Applicative
import Control.Exception
import Data.Aeson
import qualified Data.ByteString as BS
import Data.Text (Text, pack, unpack)
import Data.Text.Encoding (encodeUtf8)
import Data.Maybe
import Debug.Trace
import Network
import Network.HTTP.Conduit

type Apptoken = Text
type Receipt = Text

-- | The PushMessage data structure. To construct one of these, you should alter the message under *defaultMessage* using record syntax.
data PushMessage = PM   { token     :: Text
                        , user      :: Text
                        , message   :: Text
                        , device    :: Text
                        , title     :: Text
                        , url       :: Text
                        , urlTitle  :: Text
                        , priority  :: Int
                        , timestamp :: Text
                        , sound     :: Text
                        , callback  :: Text
                        , expire    :: Int
                        , retry     :: Int
                        } deriving (Show,Eq)

-- | When you send a PushMessage, the server replies with at least a status code and a request number. 
-- See the pushover API documentation for what each field means.
data PushResponse = PR  { status    :: Int
                        , request   :: Text
                        , receipt   :: Maybe Text
                        , errors    :: Maybe [Text]
                        } deriving (Show,Eq)

instance FromJSON PushResponse where
    parseJSON (Object o)    = PR    <$> o .: "status"
                                    <*> o .: "request"
                                    <*> o .:? "receipt" --there is only a receipt if priority was 2
                                    <*> o .:? "errors"
    parseJSON _ = fail "Unable to parse response from Pushover.net"
    
-- | The reponse you get when you inquire about a receipt for a priority 2 message. See the pushover API documentation for what each field means.
data ReceiptResponse = RR   { receiptstatus     :: Int --augh ugly, but status is already claimed by PR
                            , acknowledged      :: Int
                            , acknowledgedAt    :: Int 
                            , lastDeliveredAt   :: Int
                            , expired           :: Int
                            , expiresAt         :: Int
                            , calledBack        :: Int
                            , calledBackAt      :: Int
                            } deriving (Show,Eq)
                            
instance FromJSON ReceiptResponse where
    parseJSON (Object o)    = RR    <$> o .: "status"
                                    <*> o .: "acknowledged"
                                    <*> o .: "acknowledged_at"
                                    <*> o .: "last_delivered_at"
                                    <*> o .: "expired"
                                    <*> o .: "expires_at"
                                    <*> o .: "called_back"
                                    <*> o .: "called_back_at"
    parseJSON _ = fail "Unable to parse response from Pushover.net"


-- | A default PushMessage (all empty fields except @token@, @user@ and @message@ will be removed later in the POST request,
-- but the fields have to be there to overwrite them later (if you want)).
defaultMessage :: PushMessage
defaultMessage = PM { token     = ""  --required
                    , user      = ""  --required
                    , message   = ""  --required
                    , device    = ""  --default is to send to all devices
                    , title     = ""  --title is not necessary
                    , url       = ""  --url is usually not attached
                    , urlTitle  = ""  --url is usually not attached
                    , priority  = 0 --default priority of zero
                    , timestamp = ""  --not needed
                    , sound     = ""  --use default sound of user
                    , callback  = ""  --callback is usually not needed
                    , expire    = 0  --callback is usually not needed
                    , retry     = 0  --callback is usually not needed
                    }

-- Turn the PushMessage data structure into the fancy structure that the Pushover API actually requires
messageToBytestrings :: PushMessage -> [(BS.ByteString, BS.ByteString)]
messageToBytestrings pm = map (\(k, v) -> (encodeUtf8 k, encodeUtf8 v)) $ filter (\(x,y) -> y /= "") -- don't include any empty fields
                            [ ("token", token pm)
                            , ("user", user pm)
                            , ("message", message pm)
                            , ("device", device pm)
                            , ("title", title pm)
                            , ("url", url pm)
                            , ("url_title", urlTitle pm)
                            , ("priority", packIfNonzero $ priority pm)
                            , ("sound", sound pm)
                            , ("callback", callback pm)
                            , ("expire", packIfNonzero $ expire pm)
                            , ("retry", packIfNonzero $ retry pm)
                            ]

--small utility function to make ints behave properly with messageToBytestrings
packIfNonzero :: Int -> Text
packIfNonzero i
    | i == 0    = ""
    | otherwise = pack . show $ i

-- | Sends a push message to the Pushover servers.
sendPushMessage :: PushMessage -> IO PushResponse
sendPushMessage pm = do
    initreq' <- parseUrl "https://api.pushover.net/1/messages.json"
    let initreq = initreq' { checkStatus = \_ _ _-> Nothing } -- disables exception throwing when anything except a 200 HTTP response is received
    resp <- withManager . httpLbs $ urlEncodedBody (messageToBytestrings pm) initreq
    return . fromJust . decode . responseBody $ resp

-- | Inquire about a receipt. 
checkReceipt :: Apptoken -> Receipt -> IO ReceiptResponse
checkReceipt at rc = do --because it's a very basic GET request, we can just use simpleHTTP here
    resp <- simpleHttp $ "https://api.pushover.net/1/receipts/" ++ (unpack rc) ++ ".json?token=" ++ (unpack at)
    return . fromJust . decode $ resp
    