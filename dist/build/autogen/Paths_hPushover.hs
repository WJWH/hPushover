module Paths_hPushover (
    version,
    getBinDir, getLibDir, getDataDir, getLibexecDir,
    getDataFileName
  ) where

import qualified Control.Exception as Exception
import Data.Version (Version(..))
import System.Environment (getEnv)
catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
catchIO = Exception.catch


version :: Version
version = Version {versionBranch = [0,1], versionTags = []}
bindir, libdir, datadir, libexecdir :: FilePath

bindir     = "C:\\Users\\Wander\\AppData\\Roaming\\cabal\\bin"
libdir     = "C:\\Users\\Wander\\AppData\\Roaming\\cabal\\hPushover-0.1\\ghc-7.4.2"
datadir    = "C:\\Users\\Wander\\AppData\\Roaming\\cabal\\hPushover-0.1"
libexecdir = "C:\\Users\\Wander\\AppData\\Roaming\\cabal\\hPushover-0.1"

getBinDir, getLibDir, getDataDir, getLibexecDir :: IO FilePath
getBinDir = catchIO (getEnv "hPushover_bindir") (\_ -> return bindir)
getLibDir = catchIO (getEnv "hPushover_libdir") (\_ -> return libdir)
getDataDir = catchIO (getEnv "hPushover_datadir") (\_ -> return datadir)
getLibexecDir = catchIO (getEnv "hPushover_libexecdir") (\_ -> return libexecdir)

getDataFileName :: FilePath -> IO FilePath
getDataFileName name = do
  dir <- getDataDir
  return (dir ++ "\\" ++ name)
