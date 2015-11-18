{-# LANGUAGE TypeFamilies     #-}
{-# LANGUAGE KindSignatures   #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE DefaultSignatures #-}
module Raaz.Core.Random
  ( PRG(..), Random(..)
  ) where

import Control.Monad   (void)
import Foreign.Ptr     (castPtr)
import Foreign.Storable(Storable, peek)

import Raaz.Core.ByteSource(ByteSource, fillBytes)
import Raaz.Core.Types.Pointer  (byteSize, allocaBuffer)

-- | The class that captures pseudo-random generators. Essentially the
-- a pseudo-random generator (PRG) is a byte sources that can be
-- seeded.
class ByteSource prg => PRG prg where

  -- | Associated type that captures the seed for the PRG.
  type Seed prg :: *

  -- | Creates a new pseudo-random generators
  newPRG :: Seed prg -> IO prg

  -- | Re-seeding the prg.
  reseed :: prg -> Seed prg -> IO ()

-- | Stuff that can be generated by a pseudo-random generator.
class Random r where
  random :: PRG prg => prg -> IO r

  default random :: (PRG prg, Storable r) => prg -> IO r
  random = go undefined
    where go       :: (PRG prg, Storable a) => a -> prg -> IO a
          go w prg = let sz = byteSize w in
            allocaBuffer sz $ \ ptr -> do
              void $ fillBytes sz prg ptr
              peek $ castPtr ptr