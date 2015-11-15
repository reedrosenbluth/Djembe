module Play 
  ( hitToMidiEvent
  , play
  )
where

import Control.Monad
import Control.Monad.Trans
import Control.Monad.Trans.State
import Control.Lens
import Control.Concurrent
import System.MIDI
import System.Info

import Types
import Interpret

hitToMidiEvent :: Hit -> MidiEvent
hitToMidiEvent h = MidiEvent d (MidiMessage 10 (NoteOn t v))
  where
    t = 35 + fromEnum (h ^. tone)
    d = fromIntegral $ h ^. dur
    v = h ^. vol

getConnection :: IO Connection
getConnection = do
    dstlist <- enumerateDestinations
    case dstlist of
      [] -> error "No MIDI Devices found."
      (dst:_) -> openDestination dst

calcDurations :: Composition -> Composition
calcDurations comp = zipWith replaceDur comp durs'
  where
    durs  = map (view dur) comp
    durs' = 0 : scanl1 (+) durs 
    replaceDur h d = h & dur .~ d

play :: Composition -> IO ()
play comp = do
    conn <- getConnection
    start conn
    evalStateT runComposition (conn, calcDurations comp)
    close conn

runComposition :: StateT (Connection, Composition) IO ()
runComposition = do
  (conn, comp) <- get
  t <- lift $ currentTime conn
  case comp of
    [] -> return ()
    (h:hs) -> do
      let x@(MidiEvent s ev) = hitToMidiEvent h
      when (s < t) $ do
        put (conn, hs)
        lift $ send conn ev
      lift $ threadDelay 250
      runComposition
