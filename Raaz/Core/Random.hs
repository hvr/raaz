{-# LANGUAGE TypeFamilies      #-}
{-# LANGUAGE KindSignatures    #-}
{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE CPP               #-}
module Raaz.Core.Random
  ( PRG(..), Random(..)

#ifdef HAVE_SYSTEM_PRG
  , SystemPRG
#endif

  ) where

import Control.Monad   (void)
import Foreign.Ptr     (castPtr)
import Foreign.Storable(Storable, peek)

import Raaz.Core.ByteSource(InfiniteSource, slurpBytes)
import Raaz.Core.Types.Pointer  (byteSize, allocaBuffer, hFillBuf)

import System.IO ( openBinaryFile, Handle, IOMode(ReadMode)
                 , BufferMode(NoBuffering), hSetBuffering
                 )

-- | The class that captures pseudo-random generators. Essentially the
-- a pseudo-random generator (PRG) is a byte sources that can be
-- seeded.
class InfiniteSource prg => PRG prg where

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
              void $ slurpBytes sz prg ptr
              peek $ castPtr ptr




-- TODO: support system prg for oses that do not have @\/dev\/urandom@

#ifdef HAVE_SYSTEM_PRG

-- | The system wide pseudo-random generator. Many systems provide
-- high quality pseudo-random generator within the system like for
-- example the @\/dev\/urandom@ file on a posix system. This type
-- captures such a pseudo-random generator. The source is expected to
-- be of high quality, albeit a bit slow due to system call overheads.
-- You do not need to seed this PRG and hence the associated type
-- @`Seed` `SystemPRG`@ is the unit type @()@.
newtype SystemPRG = SystemPRG Handle

#endif

#ifdef HAVE_DEV_URANDOM
instance InfiniteSource SystemPRG where
  slurpBytes sz sprg@(SystemPRG hand) cptr = hFillBuf hand cptr sz >> return sprg


instance PRG SystemPRG where
  type Seed SystemPRG = ()

  newPRG _ = do h <- openBinaryFile "/dev/urandom" ReadMode
                hSetBuffering h NoBuffering
                return $ SystemPRG h
  reseed _ _ = return ()

#endif
