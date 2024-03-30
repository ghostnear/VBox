# CHIP8 info

Very much early in development, with debugger attached.

### Debugger usage:

By specifying the `"debug": "true"` option in the JSON of the config of the ROM you want to open, you can start using the debugger.

### Debugger commands:
- `exit`
    - Exits the emulator.
- `step` | `s`
    - Steps once.
- (`print` | `p`)
    - (`registers` | `r`)
        - Prints all the registers to the screen in hexadecimal form.
    - (`memory-byte` | `mb`) `<addr>` [`<addr_end>`]
        - Prints the byte at the specified address / address range in hexadecimal form.
    - (`memory-word` | `mw`) `<addr>` [`<addr_end>`]
        - Prints the word at the specified address / address range in hexadecimal form.
- (`dissasemble` | `disasm` | `dm`) `<size>`
    - Disassembles the next `size` opcodes of the ROM __around__ the _PC_ and prints them to the screen.
- (`breakpoint` | `bp`) `<addr>`
    - Sets a breakpoint at the specified address. __(TODO: this is not yet implemented)__

### Compatibility:

`TODO`

### Passing tests:
- [ ] Timendus' test suite
    - [ ] 1-chip8-logo.ch8