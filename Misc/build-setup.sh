#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
#
# Copyright (C) 2018 Charlie Matlack. All Rights Reserved.

die() {
	echo "[-] Error: $1" >&2
	exit 1
}

[[ ${BASH_VERSINFO[0]} -ge 4 ]] || die "bash ${BASH_VERSINFO[0]} detected, when bash 4+ required"

# TODO the conditional logic here doesn't work as desired

# unlink imagemagick if already installed & wrong version
convert --version | grep 7.0.8-9 || brew unlink imagemagick

# install older version using hard link to git commit
brew info imagemagick | grep 7.0.8-9 || brew install https://raw.githubusercontent.com/Homebrew/homebrew-core/17141e5dce0c42f9490467ed9eb204fd8e178f4c/Formula/imagemagick.rb
brew link imagemagick