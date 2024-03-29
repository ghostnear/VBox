# CHIP8 info

Very much early in development, with debugger attached.

### Debugger usage:

By specifying the `"debug": "true"` option in the JSON of the config of the ROM you want to open, you can start using the debugger.

### Debugger commands:
- `exit`
    - Closes the app and exits the emulator.
- `step` | `s`
    - Steps once through the app.
- (`print` | `p`)
    - (`registers` | `r`)
        - Prints all the registers to the screen in hexadecimal form.
    - (`memory-byte` | `mb`) `<addr>`
        - Prints the byte at the specified address in hexadecimal form.
    - (`memory-word` | `mw`) `<addr>`
        - Prints the word at the specified address in hexadecimal form.
- (`dissasemble` | `disasm` | `dm`) `<size>`
    - Disassembles the next `size` bytes of the ROM __around__ the PC and prints them to the screen.
- (`breakpoint` | `bp`) `<addr>`
    - Sets a breakpoint at the specified address. __(TODO: this is not yet implemented)__

### Compatibility:

`TODO`

### Passing tests:
- [ ] Timendus' test suite
    - [ ] 1-chip8-logo.ch8