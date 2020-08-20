{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings #-}

module Tickets where

import Control.Applicative
import qualified Data.ByteString.Char8 as BSC
import Data.Text (Text, pack)
import Data.Yaml (FromJSON (..), ToJSON (..), (.:), (.:?))
import qualified Data.Yaml as Y
import Data.Yaml.Aeson (object, (.=))
import Jira
import System.IO

newtype Title = Title Text
  deriving (Eq, Show)
  deriving newtype (FromJSON, ToJSON)

newtype UserStory = UserStory Text
  deriving (Eq, Show)
  deriving newtype (FromJSON, ToJSON)

newtype AcceptanceCriteria = AcceptanceCriteria Text
  deriving (Eq, Show)
  deriving newtype (FromJSON, ToJSON)

newtype Description = Description Text
  deriving (Eq, Show)
  deriving newtype (FromJSON, ToJSON)

data Ticket
  = StoryTicket
      { title :: Title,
        us :: UserStory,
        ac :: AcceptanceCriteria,
        desc :: Maybe Description,
        pt :: Maybe Int,
        _epic_field :: Maybe Text
      }
  | EpicTicket
      { title :: Title,
        us :: UserStory,
        ac :: AcceptanceCriteria,
        desc :: Maybe Description
      }
  deriving (Eq, Show)

storyParser obj =
  StoryTicket
    <$> (obj .: "story")
    <*> obj .: "us"
    <*> obj .: "ac"
    <*> obj .:? "desc"
    <*> obj .:? "pt"
    <*> obj .:? "epic_field"

epicParser obj =
  EpicTicket
    <$> obj .: "epic"
    <*> obj .: "us"
    <*> obj .: "ac"
    <*> obj .:? "desc"

instance FromJSON Ticket where
  parseJSON (Y.Object t) = storyParser t <|> epicParser t
  parseJSON _ = fail "Ticket not parseable"

-- ToJSON instance that converts a ticket to a Jira payload.
-- Each Jira cloud configuration is different… And this is
-- too generic to be configurable. So, if you want to add
-- additional fields (or remove some that may not be required
-- in your configuration) you can use this as an example.

data TicketWithBoard = TicketWithBoard
  { ticket :: Ticket,
    board :: Board
  }

instance ToJSON TicketWithBoard where
  toJSON
    ( TicketWithBoard
        (EpicTicket title us ac description)
        (Board project team)
      ) =
      object
        [ "fields"
            .= object
              [ pack (summary staticJiraMap) .= title,
                pack (epic_name_field staticJiraMap) .= title,
                pack (user_story staticJiraMap) .= us,
                pack (acc_crit staticJiraMap) .= ac,
                "description" .= description,
                "issuetype" .= WithId (pack (epic_id staticJiraMap)),
                "project" .= project,
                pack (_team staticJiraMap) .= team
              ]
        ]
  toJSON
    ( TicketWithBoard
        (StoryTicket title us ac description pt _epic_field)
        (Board project team)
      ) =
      object
        [ "fields"
            .= object
              ( [ pack (summary staticJiraMap) .= title,
                  pack (user_story staticJiraMap) .= us,
                  pack (acc_crit staticJiraMap) .= ac,
                  "issuetype" .= WithId (pack (story_id staticJiraMap)),
                  "project" .= project,
                  pack (_team staticJiraMap) .= team
                ]
                  ++ case pt of
                    Just pts -> [pack (points staticJiraMap) .= pts]
                    Nothing -> []
                  ++ case description of
                    Just descr -> ["description" .= descr]
                    Nothing -> []
                  ++ case _epic_field of
                    Just e_field -> [pack (epic_field staticJiraMap) .= e_field]
                    Nothing -> []
              )
        ]

filenameToTickets :: FilePath -> IO [Ticket]
filenameToTickets file = do
  handle <- openFile file ReadMode
  handleToTickets handle

handleToTickets :: Handle -> IO [Ticket]
handleToTickets handle = do
  contents <- hGetContents handle
  Y.decodeThrow (BSC.pack contents)
