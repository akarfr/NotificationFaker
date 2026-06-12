# NotificationFaker

NotificationFaker is a simple jailbreak tweak that lets you trigger fake notifications from a selected app or bundle identifier.

## What it does

- Sends a fake notification bulletin through the system notification backend
- Supports a custom sender, title, message, and bundle ID
- Includes a preferences pane for configuring test notifications

## Requirements

- A jailbroken or a bootstrapped/Nathanlr iOS device 
- Theos for building the tweak
- MobileSubstrate and PreferenceLoader installed

## Building

From the project root, run:

```bash
make package
```

This will build the tweak and the preferences bundle into a Debian package.

## Usage

1. Install the generated package on your device.
2. Open the NotificationFaker preferences.
3. Configure the sender, title, message, and target bundle ID.
4. Trigger a test notification from the preferences pane.

## Notes

This project is intended for tinkering, testing, and jailbreak tweak development. Use it responsibly.
