; MiniRV-8 demonstration program
; Store 8 at data-memory address 0x10.
; Load it, subtract 8, and halt if the result is zero.

        LDI 5
        ADDI 3
        STA 0x10
        LDI 0
        LDA 0x10
        SUBI 8
        JZ done
        LDI 99
done:   HLT
