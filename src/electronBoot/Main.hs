{-# LANGUAGE RebindableSyntax, OverloadedStrings, EmptyDataDecls #-}

import Prelude
import FFI
import Fay.Text

data Electron
data App
data BrowserWindow
data MainWindow

class OnCaller a

instance OnCaller App
instance OnCaller MainWindow

type DirName = Text

main :: Fay ()
main = bootApp

bootApp :: Fay ()
bootApp = do
  electron' <- electron
  app' <- app electron'
  onEvent app' "ready" setupMainWindow
  onEvent app' "window-all-closed" $ do
    processPlatform' <- processPlatform
    when (processPlatform' /= "darwin") $ callAppProp app' "quit"
  onEvent app' "activate" $ void $ do
    nullableMainWindow <- getMainWindow
    case nullableMainWindow of
      Nullable _ -> return ()
      Null -> setupMainWindow

electron :: Fay Electron
electron = ffi "require('electron')"

processPlatform :: Fay Text
processPlatform = ffi "process.platform"

app :: Electron -> Fay App
app = ffi "%1['app']"

callAppProp :: App -> Text -> Fay ()
callAppProp = ffi "%1[%2]()"

browserWindow :: Electron -> Fay BrowserWindow
browserWindow = ffi "%1['BrowserWindow']"

dirName :: Fay DirName
dirName = ffi "(function () { return __dirname; })()"

windowWidth :: Int
windowWidth = 800

windowHeight :: Int
windowHeight = 600

windowIcon :: DirName -> Fay Text
windowIcon = ffi "(function (d) { return d + '/icon.png'; })(%1)"

newMainWindow :: BrowserWindow -> Int -> Int -> Text -> Fay MainWindow
newMainWindow = ffi "(function (b) { return global['mainWindow'] = new b({ width: %2, height: %3, icon: %4 }); })(%1)"

getMainWindow :: Fay (Nullable MainWindow)
getMainWindow = ffi "(function () { var m = global['mainWindow']; return m ? m : null; })()"

onEvent :: OnCaller a => a -> Text -> Fay () -> Fay ()
onEvent = ffi "%1['on'](%2, %3)"

loadUrl :: MainWindow -> DirName -> Fay ()
loadUrl = ffi "%1['loadURL']('file://' + %2 + '/index.html')"

setMainWindowNull :: Fay ()
setMainWindowNull = ffi "(function () { global['mainWindow'] = null; })()"

hideMainWindowMenu :: MainWindow -> Fay ()
hideMainWindowMenu = ffi "%1['setMenu'](null)"

setupMainWindow :: Fay ()
setupMainWindow = do
  nullableMainWindow <- getMainWindow
  mainWindow <- case nullableMainWindow of
                  Nullable mainWindow -> return mainWindow
                  Null -> do
                    electron' <- electron
                    browserWindow' <- browserWindow electron'
                    iconFile <- dirName >>= windowIcon
                    newMainWindow browserWindow' windowWidth windowHeight iconFile
  dirName >>= loadUrl mainWindow
  hideMainWindowMenu mainWindow
  onEvent mainWindow "close" setMainWindowNull
