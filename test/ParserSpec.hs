--{-# LANGUAGE OverloadedStrings #-}
--{-# LANGUAGE QuasiQuotes #-}

--import Control.Applicative

module ParserSpec where

import Story
import Test.Hspec
import Text.Parsec (parse)
import Prelude

--parse rule text = Parsec.parse rule "(source)" text

expectationSuccess :: Expectation
expectationSuccess = True `shouldBe` True

leftie uh = expectationFailure (show uh)

eitherShouldBe returned expected = case returned of
  Right value -> do
    value `shouldBe` expected
  Left uh -> leftie uh

spec :: Spec
spec = do
  describe "Parsec standard User Story parsing and reformating" $ do
    it "parses a USER block (a)" $ do
      let parsed = parse userBlockParser "" "As a Haskell programmer, I want to "
      parsed `eitherShouldBe` ("As a ", "Haskell programmer")
    it "parses a USER block (an)" $ do
      let parsed = parse userBlockParser "" "As an Idris programmer, I want to "
      parsed `eitherShouldBe` ("As an ", "Idris programmer")

    it "parses a GOAL block" $ do
      let parsed = parse goalBlockParser "" "I want to write code so that foo"
      parsed `eitherShouldBe` "write code"

    it "parses a REASON block" $ do
      let parsed = parse reasonBlockParser "" "so that yadda yadda yadda"
      parsed `eitherShouldBe` "yadda yadda yadda"

    it "parses the whole enchilada" $ do
      let parsed = parse userStoryParser "" "As a foo, I want to bar so that I can baz"
      parsed `eitherShouldBe` (("As a ", "foo"), "bar", "I can baz")

    it "reformats the user story" $ do
      let parsed = parse userStoryParser "" "As a foo, I want to bar so that I can baz"
      let reformatted = fmap userStoryReformatter parsed
      reformatted `eitherShouldBe` "As a foo\nI want to bar\nso that I can baz"
