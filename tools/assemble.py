#!/usr/bin/env python3
"""Two-pass assembler for the educational MiniRV-8 ISA."""

import argparse
import re
import sys
from pathlib import Path

INSTRUCTIONS = {
    "NOP": (0x00, 0),
    "LDI": (0x10, 1),
    "ADDI": (0x20, 1),
    "SUBI": (0x30, 1),
    "JMP": (0x40, 1),
    "JZ": (0x50, 1),
    "STA": (0x60, 1),
    "LDA": (0x70, 1),
    "HLT": (0xF0, 0),
}

LABEL_PATTERN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def number(text):
    """Parse decimal, 0x-prefixed hexadecimal, or 0b-prefixed binary."""
    try:
        return int(text, 0)
    except ValueError as exc:
        raise ValueError(f"invalid numeric operand: {text}") from exc


def parse_source(path):
    lines = []
    labels = {}
    pc = 0

    for line_number, original in enumerate(
        path.read_text(encoding="utf-8-sig").splitlines(), start=1
    ):
        source = original.split(";", 1)[0].split("#", 1)[0].strip()
        if not source:
            continue

        if ":" in source:
            label, source = source.split(":", 1)
            label = label.strip()
            if not LABEL_PATTERN.fullmatch(label):
                raise ValueError(f"line {line_number}: invalid label '{label}'")
            if label in labels:
                raise ValueError(f"line {line_number}: duplicate label '{label}'")
            labels[label] = pc
            source = source.strip()
            if not source:
                continue

        parts = source.replace(",", " ").split()
        mnemonic = parts[0].upper()

        if mnemonic not in INSTRUCTIONS:
            raise ValueError(f"line {line_number}: unknown instruction '{mnemonic}'")

        opcode, operand_count = INSTRUCTIONS[mnemonic]
        if len(parts) != operand_count + 1:
            raise ValueError(
                f"line {line_number}: {mnemonic} expects "
                f"{operand_count} operand(s)"
            )

        lines.append((line_number, pc, mnemonic, parts[1:]))

        pc += 1 + operand_count
        if pc > 256:
            raise ValueError(f"line {line_number}: program exceeds 256 bytes")

    return lines, labels, pc


def assemble(path):
    lines, labels, size = parse_source(path)
    output = []

    for line_number, pc, mnemonic, operands in lines:
        opcode, operand_count = INSTRUCTIONS[mnemonic]
        output.append(opcode)

        if not operand_count:
            continue

        operand_text = operands[0]

        if mnemonic in ("JMP", "JZ") and operand_text in labels:
            # Relative displacement is measured from the byte after the operand.
            value = labels[operand_text] - (pc + 2)
            if not -128 <= value <= 127:
                raise ValueError(
                    f"line {line_number}: branch to '{operand_text}' "
                    f"is out of signed 8-bit range"
                )
            value &= 0xFF
        else:
            value = number(operand_text)

            if mnemonic in ("JMP", "JZ"):
                if not -128 <= value <= 255:
                    raise ValueError(
                        f"line {line_number}: branch offset must fit in 8 bits"
                    )
                value &= 0xFF
            elif not 0 <= value <= 255:
                raise ValueError(
                    f"line {line_number}: operand must be between 0 and 255"
                )

        output.append(value)

    if len(output) != size:
        raise AssertionError("internal assembler size mismatch")

    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="input .asm file")
    parser.add_argument(
        "-o", "--output", type=Path,
        help="output hex file (default: build/program.hex)",
    )
    args = parser.parse_args()

    try:
        machine_code = assemble(args.source)
        output_path = args.output or Path("build/program.hex")
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(
            "".join(f"{byte:02X}\n" for byte in machine_code),
            encoding="ascii",
        )
        print(f"PASS: assembled {len(machine_code)} byte(s)")
        print(f"Output: {output_path}")
    except (OSError, ValueError) as exc:
        print(f"ASSEMBLER ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)


if __name__ == "__main__":
    main()

