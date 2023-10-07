### [Back to the main document.](../README.md)

# CHIP8

## Information used

- [Awesome CHIP8](https://chip-8.github.io/links/)
- [Timendus' CHIP8 test suite](https://github.com/Timendus/chip8-test-suite)

## Issues:

- Nothing so far.

## Passed tests:

- [ ] Timendus' CHIP8 test suite
    - [x] CHIP8 logo.
    - [x] IBM logo.
    - [x] Corax+
    - [x] Flags
    - [ ] Quirks
        - no waiting for 60Hz VBlank in normal CHIP8 mode (unimplemented, probably won't be).
            - this also creates speed issues for CHIP8 when the emulator speed is set too high, setting it lower fixes it.
    - [x] Keypad