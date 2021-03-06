{-# LANGUAGE CPP #-}
module Common.Utils where

import Common.Imports hiding (length, replicate)

import Data.ByteString as B  (concat)

-- | Run a spec with a give key.
with :: key -> (key -> Spec) -> Spec
with key hmsto = hmsto key

-- | Store and the load the given value.
storeAndThenLoad :: EndianStore a
                 => a -> IO a
storeAndThenLoad a = allocaBuffer (byteSize a) runStoreLoad
  where runStoreLoad ptr = store ptr a >> load ptr

-- | Shorten a string to make it readable in tests.
shortened :: String -> String
shortened x | l <= 11    = paddedx
            | otherwise  = prefix ++ "..." ++ suffix
  where l = length x
        prefix = take  4 x
        suffix = drop (l - 4) x
        paddedx = x ++ replicate (11 - l) ' '

genEncodable :: (Encodable a, Storable a) => Gen a
genEncodable = go undefined
  where go :: (Encodable a, Storable a) => a -> Gen a
        go x = unsafeFromByteString . pack <$> vector (sizeOf x)

-- | Generate bytestrings that are multiples of block size of a
-- primitive.
blocks :: Primitive prim => prim -> Gen ByteString
blocks prim = B.concat <$> listOf singleBlock
  where singleBlock = pack <$> vector sz
        BYTES sz    = blockSize prim


-- | Run a property with a given generator.
feed :: (Testable pr, Show a)
     => Gen a -> (a -> IO pr) -> Property
feed gen pr = monadicIO $ pick gen >>= (run . pr)

repeated :: Monoid m => m -> Int -> m
repeated m n = mconcat $ replicate n m
