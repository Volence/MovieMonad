# Steve Meyer (C) 2021
# https://www.volence.dev/

.RECIPEPREFIX != ps
PROJECT_NAME = movieMonad
HASKELL_PACKAGE_SANDBOX = /home/volence/.stack/snapshots/x86_64-linux-tinfo6/0787f89fe32c828accac0c26d513bf5e99fce79ad96fb55f3d35b66c5cb86396/7.10.3/pkgdb/
FAY_PACKAGES = fay-jquery,fay-text
FAY_CC = HASKELL_PACKAGE_SANDBOX=$(HASKELL_PACKAGE_SANDBOX) fay --package $(FAY_PACKAGES) -p --Wall

all: build runElectron

build: clean gatherDependencies buildHaskell copyConf copyIcon buildElectronDists

clean: cleanDist cleanBin

cleanDist:
  mkdir -p dist && mkdir -p dist_old && rm -rf dist_old && mv -f dist dist_old && mkdir -p dist

cleanBin:
  mkdir -p bin && mkdir -p bin_old && rm -rf bin_old && mv -f bin bin_old && mkdir -p bin

gatherDependencies: installStackDependencies downloadJquery

installStackDependencies:
  stack install --dependencies-only

downloadJquery:
  wget http://ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js -O dist/jquery.js

buildHaskell: buildHtml buildCss buildJs

buildHtml:
  stack ghc -- src/html/Main.hs -o bin/$(PROJECT_NAME)Html && bin/$(PROJECT_NAME)Html > dist/index.html

buildCss:
  stack ghc -- src/css/Main.hs -o bin/$(PROJECT_NAME)Css && bin/$(PROJECT_NAME)Css > dist/all.css

buildJs:
  $(FAY_CC) -o dist/all.js src/js/Main.hs && \
  $(FAY_CC) -o dist/boot.js src/electronBoot/Main.hs

copyIcon:
  cp branding/icon.png dist/

copyConf:
  cp -R conf/. dist/

buildElectronDists:
  mkdir -p dist/electronDists/ && electron-packager dist/ --all --version 0.37.2 --out dist/electronDists

runElectron:
  electron dist/
