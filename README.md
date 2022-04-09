# SUPL iOS

This repository contains the client code of the now retired [SUPL iOS app](https://twitter.com/suplco).

> **Create gorgeous product pages with full-screen autoplay videos, just like Instagram Stories.**

[![suple screenshots](Marketing%20Assets/supl_screenshots.png)](Marketing%20Assets/supl_screenshots.png)

![](Marketing%20Assets/supl_shug_insta_first_product.gif)


## Installation

- Install [Xcode 10](https://developer.apple.com/)
- Install [Homebrew](https://brew.sh/)
- Run `make bootstrap` to install tools and dependencies
- Now open the `ZShop.xcworkspace` project file
- You can now build and run on the simulator or directly on your device

## Makefile

- To to build the app: `make build`
- To to build and run tests on all frameworks: `make test-all`
- To kickoff a new beta build: `make beta`
- To manually increment the build number: `make increment-build`
