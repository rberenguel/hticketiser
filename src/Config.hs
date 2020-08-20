{-# LANGUAGE OverloadedStrings #-}

module Config where

import qualified Data.ByteString.Char8 as BSC
import Data.Yaml (FromJSON (..), (.:))
import qualified Data.Yaml as Y
import System.IO

data JiraConfig = JiraConfig
  { path :: String,
    auth :: String
  }
  deriving (Eq, Show)

instance FromJSON JiraConfig where
  parseJSON (Y.Object obj) =
    JiraConfig
      <$> obj .: "path"
      <*> obj .: "auth"
  parseJSON _ = fail "Jira response not parseable (error)"

loadConfig :: FilePath -> IO JiraConfig
loadConfig file = do
  handle <- openFile file ReadMode
  contents <- hGetContents handle
  Y.decodeThrow (BSC.pack contents)
