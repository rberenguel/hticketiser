{-# LANGUAGE OverloadedStrings #-}

module API where

import Config
import Control.Exception
import Data.Aeson (FromJSON (..), encode, (.:))
import qualified Data.Aeson as A
import Data.ByteString.Char8 (ByteString, pack)
import qualified Data.Text as T
import Network.HTTP.Simple
import Network.HTTP.Types.Header (HeaderName)
import Tickets

headers :: String -> [(HeaderName, ByteString)]
headers auth =
  [ ("accept", "application/json"),
    ("content-type", "application/json"),
    ("authorization", (pack ("Basic " ++ auth)))
  ]

data ApiResponse = ApiResponse
  { self :: String,
    key :: String,
    _id :: String
  }
  deriving (Show)

instance FromJSON ApiResponse where
  parseJSON (A.Object obj) =
    ApiResponse
      <$> obj .: "self"
      <*> obj .: "key"
      <*> obj .: "id"
  parseJSON _ = fail "Api response is not valid JSON"

sendOneTicket :: JiraConfig -> Maybe String -> TicketWithBoard -> IO (Maybe String)
sendOneTicket (JiraConfig path auth) epic (TicketWithBoard ticket board) = do
  request <- parseRequest ("POST " ++ path ++ "/rest/api/2/issue")
  res <- httpJSONEither (configureRequest request)
  let ticketKey = case getResponseBody res of
        Right r -> key (r :: ApiResponse)
        Left l -> throw l
  putStrLn (path ++ "/browse/" ++ ticketKey)
  return
    ( case ticket of
        EpicTicket {} -> Just ticketKey
        _ -> epic
    )
  where
    configureRequest r =
      setRequestHeaders (headers auth) $
        setRequestBodyLBS
          ( case (epic, ticket) of
              (Just epic, StoryTicket {}) ->
                ( encode
                    ( TicketWithBoard
                        ticket {_epic_field = Just (T.pack epic)}
                        board
                    )
                )
              _ -> encode (TicketWithBoard ticket board)
          )
          r
