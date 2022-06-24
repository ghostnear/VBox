# VBox - Multiplatform emulator written in V

## Current targets
- [ ] Have a BytePusher virtual machine.
- [ ] Have a working GUI to manage ROM files.
- [ ] Make the VM render to the screen.
- [ ] Make the VM produce sound.
- [ ] Have a CHIP8 virtual machine.
- etc

## Requirements

- [vlang](https://github.com/vlang/v) - V programming language
- [ui](https://github.com/vlang/ui) - UI module for V.

## How to run / build the app

The simplest way to run / build the app is by running the platform specific file from the scripts/ folder.

If you want to build the app, the executable should be in a newly created bin/ folder after you run the script.

## If you want to help

If you found a bug / want a feature to be added, you can submit an issue with how to trigger it so it can be solved and a description would help as well.

If you want to contribute, make sure to submit a pull request with your changes.

What to look out for when contributing:
- make sure your commits are squashed and that the final commit's name is 'Fix for issue x' where x is the id.
- make sure your code is commented or at least readable and understandable. Helps everyone else a lot.
- make sure your changes actually solve the issues you mention, at least on a surface level. Time will tell if it really worked.