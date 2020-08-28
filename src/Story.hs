{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE OverloadedStrings #-}

module Story where

import Control.Exception
import Control.Monad.Identity (Identity)
import Data.Text (Text, pack, unpack)
import Text.Parsec ((<|>))
import qualified Text.Parsec as Parsec

asaBlock = "As a"

wantBlock = "I want to "

soBlock = "so that "

userBlockParser :: Parsec.ParsecT String () Identity (String, String)
userBlockParser = do
  Parsec.string asaBlock
  matcher <- Parsec.string "n " <|> Parsec.string " "
  user <- Parsec.manyTill Parsec.anyChar tryParseWantBlock
  return (asaBlock ++ matcher, user)
  where
    tryParseWantBlock = Parsec.try (Parsec.string (", " ++ wantBlock))

goalBlockParser :: Parsec.ParsecT String () Identity String
goalBlockParser = do
  Parsec.optional (Parsec.string wantBlock)
  Parsec.manyTill Parsec.anyChar tryParseSpacedSoBlock
  where
    spacedSoBlock = " " ++ soBlock
    tryParseSpacedSoBlock = Parsec.try (Parsec.string spacedSoBlock)

reasonBlockParser :: Parsec.ParsecT String () Identity String
reasonBlockParser = do
  Parsec.optional (Parsec.string soBlock)
  Parsec.many Parsec.anyChar

userStoryParser :: Parsec.ParsecT String () Identity ((String, String), String, String)
userStoryParser = do
  user <- userBlockParser
  goal <- goalBlockParser
  reason <- reasonBlockParser
  return (user, goal, reason)

userStoryReformatter ((first, user), goal, reason) =
  first ++ user ++ "\n" ++ wantBlock ++ goal ++ "\n" ++ soBlock ++ reason

data StoryParsingException = StoryParsingException !String deriving (Show)

instance Exception StoryParsingException

reformatUserStory :: Text -> Text
reformatUserStory userStory = do
  let parsed = Parsec.parse userStoryParser "" (unpack userStory)
  let reformatted = fmap userStoryReformatter parsed
  case reformatted of
    Right story -> pack story
    Left uh -> throw (StoryParsingException (show uh))
