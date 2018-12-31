#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
#
# Copyright (C) 2018 Charlie Matlack. All Rights Reserved.

die() {
	echo "[-] Error: $1" >&2
	exit 1
}

[[ ${BASH_VERSINFO[0]} -ge 4 ]] || die "bash ${BASH_VERSINFO[0]} detected, when bash 4+ required"

# Ensure XCode and Homebrew are installed
type xcodebuild >/dev/null || echo "You need to install XCode from the Apple Store"
type brew >/dev/null || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" || die "Failed to install Homebrew"

# Imagemagick 7.0.8-9 must be used to avoid bug in floodfill. Homebrew can be brute-forced to specific version:
# 1) unlink imagemagick if already installed & wrong version
type convert >/dev/null || convert --version | grep 7.0.8-9 || brew unlink imagemagick
# 2) install older version using hard link to git commit
brew info imagemagick | grep 7.0.8-9 || brew install https://raw.githubusercontent.com/Homebrew/homebrew-core/17141e5dce0c42f9490467ed9eb204fd8e178f4c/Formula/imagemagick.rb
# 3) link if installed and not linked
convert --version | grep 7.0.8-9 || brew link imagemagick

# Invoke Brewfile in top-level dir to install remaining dependencies available from Homebrew
cd "${0%/*}/../" && brew bundle

