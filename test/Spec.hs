import qualified ParserSpec
import Test.Hspec
import qualified YamlSpec

main :: IO ()
main = hspec spec

spec :: Spec
spec = do
  describe "Story parsing with Parsec" ParserSpec.spec
  describe "From YAML to tickets" YamlSpec.spec
