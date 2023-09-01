### [Back to the main document.](../README.md)

# Gameboy

## Information used

- [emudev.org](https://emudev.org/)
- [Gameboy test ROMs suite](https://github.com/c-sp/gameboy-test-roms)
- [Algorithmically decode opcodes](https://gb-archive.github.io/salvage/decoding_gbz80_opcodes/Decoding%20Gamboy%20Z80%20Opcodes.html)

## Passing tests:

- Blargg’s test ROMs
    - cpu_instrs
        - individual
            - [ ] 01-special.gb - unimplemented opcode
            - [x] 04-op r,imm.gb
            - [ ] 05-op rp.gb - unimplemented opcode
            - [ ] 07-jr,jp,call,ret,rst.gb - unimplemented opcode
            - [ ] 09-op r,r.gb - unimplemented opcode
            - [x] 10-bit ops.gb