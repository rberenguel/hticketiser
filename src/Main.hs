{-# LANGUAGE OverloadedStrings #-}

module Main where

import API
import Config
import Control.Monad (foldM_)
import Jira (Board, red, sas)
import Options.Applicative
import System.Directory
import System.FilePath (joinPath, splitPath)
import System.IO
import Tickets
import Prelude

data CLIConfig = CLIConfig
  { filename :: String,
    team :: String,
    configPath :: String
  }

defaultConfigFilePathString :: String
defaultConfigFilePathString = "~/.hticketiser.yaml"

cliConfig :: Parser CLIConfig
cliConfig =
  CLIConfig
    <$> strArgument (metavar "FILEPATH" <> help "Ticket file")
    <*> strOption
      ( long "board"
          <> short 'b'
          <> metavar "BOARD ID"
          <> help "Board to send it to"
          <> value "SAS"
          <> showDefault
      )
    <*> strOption
      ( long "configPath"
          <> short 'c'
          <> metavar "FILEPATH"
          <> help "Path to config file"
          <> value defaultConfigFilePathString
          <> showDefault
      )

getFullPath :: FilePath -> IO FilePath
getFullPath s = case splitPath s of
  "~/" : t -> joinPath . (: t) <$> getHomeDirectory
  _ -> return s

getProjectAndTeam :: String -> Board
getProjectAndTeam board = case board of
  "SAS" -> sas
  "RED" -> red
  _ -> error "Board not available"

addBoard board ticket =
  TicketWithBoard ticket board

start :: CLIConfig -> IO ()
start (CLIConfig ticketsFilePath board configFilePath) = do
  configPath <- getFullPath configFilePath
  ticketsPath <- getFullPath ticketsFilePath
  jiraConfig <- loadConfig configPath
  let board_ = getProjectAndTeam board
  tickets <- filenameToTickets ticketsPath
  let ticketsWithboard = map (addBoard board_) tickets
  foldM_ (sendOneTicket jiraConfig) Nothing ticketsWithboard

main :: IO ()
main = do
  start =<< execParser opts
  where
    opts =
      info
        (cliConfig <**> helper)
        ( fullDesc
            <> progDesc "Parse TARGET file (YAML) and send it as tickets to Jira"
            <> header "The Ticketiser 2, now with more types"
        )
