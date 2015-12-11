module TypesSpec where

import Test.Hspec
import Test.QuickCheck

import Types
import Interpret

main :: IO ()
main = hspec spec

spec :: Spec
spec = do
  describe "associative property" $ do
    it "fail" $ 1 `shouldBe` (1 :: Int)
    it "of series" $
      property $
        \x y z -> toHits ((x >> y) >> z)
               == toHits ((x :: Song) >> ((y :: Song) >> (z :: Song)))