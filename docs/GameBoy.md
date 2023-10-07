### [Back to the main document.](../README.md)

# Gameboy

## Information used

- [emudev.org](https://emudev.org/)
- [Gameboy test ROMs suite](https://github.com/c-sp/gameboy-test-roms)
- [Algorithmically decode opcodes](https://gb-archive.github.io/salvage/decoding_gbz80_opcodes/Decoding%20Gamboy%20Z80%20Opcodes.html)

## Test results:

- Blargg’s test ROMs
    - cpu_instrs
        - individual
            - [x] 01-special.gb
            - [ ] 02-interrupts.gb
                - Unimplemented interrupts.
            - [x] 03-op sp,hl.gb
            - [x] 04-op r,imm.gb
            - [x] 05-op rp.gb
            - [x] 06-ld r,r.gb
            - [ ] 07-jr,jp,call,ret,rst.gb
                - Mismatch in CPU state at line 205978 (previous opcode: 0xC2 JP NZ a16)
                - Unknown opcode D9 detected at PC DEF8! Debug data (x: 3, y: 3, z: 1, p: 1, q: 1)
            - [x] 08-misc instrs.gb
            - [x] 09-op r,r.gb
            - [x] 10-bit ops.gb
            - [x] 11-op a,(hl).gb