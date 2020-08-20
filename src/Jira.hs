{-# LANGUAGE OverloadedStrings #-}

module Jira where

import Data.Text
import Data.Yaml.Aeson (ToJSON (..), object, (.=))

newtype WithId = WithId
  { id :: Text
  }
  deriving (Eq, Show)

instance ToJSON WithId where
  toJSON (WithId id) = object ["id" .= id]

{-
Specific configuration for a Jira cloud instance.
These fields will have different identifiers for
different setups. They will be shared across projects,
though (although some might not be visible). The set-up
defined here is used in Tickets.hs during serialisation
to convert to API payloads. Tweak as needed by checking
error messages from exceptions until you get it right.

To get the initial identifiers for fields, open your
Jira path (while logged-in) /rest/api/2/issue/ISSUE IDENTIFIER

Here you can find all the fields. Have… fun.
-}

data JiraMap = JiraMap
  { summary :: String,
    user_story :: String,
    acc_crit :: String,
    points :: String,
    epic_field :: String,
    epic_name_field :: String,
    epic_id :: String,
    story_id :: String,
    _team :: String
  }

staticJiraMap :: JiraMap
staticJiraMap =
  JiraMap
    "summary"
    "customfield_11900"
    "customfield_11901"
    "customfield_10004"
    "customfield_10008"
    "customfield_10009"
    "10000"
    "10001"
    "customfield_14500"

data Board = Board
  { project :: WithId,
    team :: WithId
  }

sas :: Board
sas =
  Board
    (WithId "11400")
    (WithId "12401")

red :: Board
red =
  Board
    (WithId "12108")
    (WithId "12614")
