{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE RecordWildCards #-}
-- |
--
-- N.B. Module extracted primarily for testability.
--
module Restyler.Run
    ( callRestylers
    ) where

import ClassyPrelude

import Restyler.Config
import Restyler.Process (callProcess)
import System.Directory (doesFileExist, getCurrentDirectory)

callRestylers :: Config -> [FilePath] -> IO ()
callRestylers Config{..} paths = do
    paths' <- filterM doesFileExist paths
    traverse_ (callRestyler paths') cRestylers

callRestyler :: [FilePath] -> Restyler -> IO ()
callRestyler paths r = do
    cwd <- getCurrentDirectory
    paths' <- restylePaths r paths

    unless (null paths')
        $ callProcess "docker"
        $ dockerArguments cwd r paths'

dockerArguments :: FilePath -> Restyler -> [FilePath] -> [String]
dockerArguments dir Restyler{..} paths =
    [ "run", "--rm"
    , "--volume", dir <> ":/code"
    , "--net", "none"
    , "restyled/restyler-" <> rName
    , rCommand
    ]
    ++ rArguments ++ prependArgSep (map prependIfRelative paths)
  where
    prependArgSep
        | rSupportsArgSep = ("--":)
        | otherwise = id

    prependIfRelative path
        | any (`isPrefixOf` path) ["/", "./", "../"] = path
        | otherwise = "./" <> path
