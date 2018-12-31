[![Maintainability](https://api.codeclimate.com/v1/badges/0192a3dc06d9c270913e/maintainability)](https://codeclimate.com/github/eecharlie/macos-menubar-wireguard/maintainability)
[![Build Status](https://travis-ci.org/aequitas/macos-menubar-wireguard.svg?branch=master)](https://travis-ci.org/eecharlie/macos-menubar-wireguard)

This is a macOS statusbar item (aka menubar icon) for WireGuard.

<img src=Misc/demo.png width="400">


# Features

- Sit in your menubar
- Indicate if tunnels are enabled
- Bring tunnel up/down via one click
- This fork has changes to streamline use with [Mullvad VPN](https://mullvad.net)

# Installation

- Download this App from [Releases](https://github.com/eecharlie/macos-menubar-wireguard/releases)
- Open the .dmg and 
- run Mullvad-Setup to install WireGuard and configure with your Mullvad account, _or_ 
- run Setup to _just_ install WireGuard dependencies, then 
- copy the Application to where you like (eg: '/Applications')
- Start the App and get a dialog indicating the app is not signed
- Go to: Preferences->Security & Privacy->General and click "Open Anyway"

# Building & Testing

Automation scripting is provided in this repository to make development a little easier. Primary development using Xcode is supported/preferred but some actions (integration testing, distribution build) are only available using `make`.

To test the project and check code quality run:

    make test-unit

Integration tests require preparation and will ask for a `sudo` password to install a test configuration file in `/etc/wireguard`:

    make test-integration

Code formatting should preferably by done by computers. To auto correct most violations run (this is also run before each `make test` or `make check`):

    make fix

To completely verify/test the project, build a distributable `.dmg` and install to `/Applications` simply run:

    make

Or explore `make` with tab completion for other options.

# Architecture/Security

- This application is split into two parts. The Application and a [Privileged Helper](https://developer.apple.com/library/archive/documentation/Security/Conceptual/SecureCodingGuide/Articles/AccessControl.html).
- The App will sit in the menubar after launching and handle all UI interaction and logic.
- Whenever the App needs to perform actions requiring Administrator privileges (eg: start/stop tunnel, read configurations) it will communicate with the Helper via XPC to have these actions performed.
- The Helper is installed as a [Privileged Launchd daemon](https://developer.apple.com/documentation/servicemanagement/1431078-smjobbless?language=objc) during the startup of the App. The user will be prompted for credentials during this action.
- Logic/responsability in the Helper is kept to a minimum and communication between the App and the Helper is in simple primitives to reduce attack surface of the Helper.
- The Helper should not allow an unprivileged attacker to perform any actions via the XPC that would not be possible to perform when using the App.
- Both the App and the Helper are signed and these signatures will be verified on Helper installation.
- The Helper will only run during the runtime of the Application.
- The Helper notifies the App on any change in the WireGuard configuration/runtime state. The App will then query the Helper to allow rebuilding its menus.

# License

This software as a whole is licensed under GPL-3.0

"WireGuard" and the "WireGuard" logo are registered trademarks of Jason A. Donenfeld.

# Todo/Readmap

- (see parent of this fork)
- Recent tunnels on top option
- Active tunnels on top option
- Show ping results for recently-used servers
