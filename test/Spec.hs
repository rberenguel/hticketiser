{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

import Data.Aeson.Encode.Pretty (encodePretty)
import qualified Data.ByteString.Lazy.Char8 as B
import qualified Data.Yaml as Y
import Jira
import Test.Hspec
import Text.RawString.QQ
import Tickets
import Prelude

s1 =
  [r|
- story: a
  us: b
  ac: c
  pt: 1
|]

s2 =
  [r|
- story: a
  us: b
  ac: c
|]

e1 =
  [r|
- epic: a
  us: b
  ac: c
|]

s1d =
  [ StoryTicket
      (Title "a")
      (UserStory "b")
      (AcceptanceCriteria "c")
      Nothing
      (Just 1)
      Nothing
  ]

s2d =
  [ StoryTicket
      (Title "a")
      (UserStory "b")
      (AcceptanceCriteria "c")
      Nothing
      Nothing
      Nothing
  ]

e1d = [EpicTicket (Title "a") (UserStory "b") (AcceptanceCriteria "c") Nothing]

main :: IO ()
main = hspec $ do
  describe "Ticket parsing" $ do
    it "parses a single correct ticket" $ do
      items <- Y.decodeThrow s1
      items `shouldBe` (s1d :: [Ticket])
    it "parses a ticket with no points" $ do
      items <- Y.decodeThrow s2
      items `shouldBe` (s2d :: [Ticket])
    it "parses an epic" $ do
      items <- Y.decodeThrow e1
      items `shouldBe` (e1d :: [Ticket])
  describe "Ticket to JSON Payload" $ do
    it "should be a nice JSON ticket (this tests just prints)" $ do
      B.putStrLn (encodePretty (TicketWithBoard (head e1d) sas))
      True `shouldBe` True
