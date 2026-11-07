#!/usr/bin/env python3

"""
Minimal QR code generator.

Features:
- No external dependencies.
- QR versions 1-5.
- Error correction level L.
- Byte encoding.
- Reed-Solomon error correction.
- Mask pattern 0.
- Terminal rendering.
- Importable from other Python scripts.

Usage:
    python qr.py 192.168.1.50 8080
    python qr.py 192.168.1.50
    python qr.py http://192.168.1.50:8080
    python qr.py 192.168.1.50 443 --https

Python API:
    from qr import generate_qr, print_qr

    print_qr("http://192.168.1.50:8080")
"""

import sys
import argparse


# QR Version 1-5, Error Correction Level L.
# Each version uses one Reed-Solomon block.
VERSIONS = {
    1: (19, 7),
    2: (34, 10),
    3: (55, 15),
    4: (80, 20),
    5: (108, 26),
}


# ---------------------------------------------------------
# Galois Field GF(256)
# ---------------------------------------------------------

def gf_mul(x, y):
    result = 0

    while y:
        if y & 1:
            result ^= x

        y >>= 1
        x <<= 1

        if x & 0x100:
            x ^= 0x11D

    return result


def gf_pow(x, power):
    result = 1

    for _ in range(power):
        result = gf_mul(result, x)

    return result


# ---------------------------------------------------------
# Reed-Solomon error correction
# ---------------------------------------------------------

def rs_generator(n):
    polynomial = [1]

    for i in range(n):
        result = [0] * (len(polynomial) + 1)

        for j, value in enumerate(polynomial):
            result[j] ^= value
            result[j + 1] ^= gf_mul(value, gf_pow(2, i))

        polynomial = result

    return polynomial


def rs_encode(data, ecc_count):
    generator = rs_generator(ecc_count)
    result = data + [0] * ecc_count

    for i in range(len(data)):
        factor = result[i]

        for j, coefficient in enumerate(generator):
            result[i + j] ^= gf_mul(coefficient, factor)

    return result[-ecc_count:]


# ---------------------------------------------------------
# Bit encoding
# ---------------------------------------------------------

def encode_data(text, version):
    data_bytes = text.encode("utf-8")

    data_capacity, ecc_count = VERSIONS[version]

    bits = []

    def append_bits(value, count):
        for i in reversed(range(count)):
            bits.append((value >> i) & 1)

    # Byte mode
    append_bits(0b0100, 4)

    # Character count
    append_bits(len(data_bytes), 8)

    # Payload
    for byte in data_bytes:
        append_bits(byte, 8)

    capacity = data_capacity * 8

    # Terminator
    bits.extend([0] * min(4, capacity - len(bits)))

    # Byte alignment
    while len(bits) % 8:
        bits.append(0)

    # Convert to bytes
    data = []

    for i in range(0, len(bits), 8):
        value = 0

        for bit in bits[i:i + 8]:
            value = (value << 1) | bit

        data.append(value)

    # Padding
    padding = [0xEC, 0x11]
    index = 0

    while len(data) < data_capacity:
        data.append(padding[index % 2])
        index += 1

    # Error correction
    ecc = rs_encode(data, ecc_count)

    return data + ecc


# ---------------------------------------------------------
# QR matrix construction
# ---------------------------------------------------------

def create_matrix(version):
    size = 17 + version * 4

    matrix = [[None] * size for _ in range(size)]
    function = [[False] * size for _ in range(size)]

    def set_function(x, y, value):
        if 0 <= x < size and 0 <= y < size:
            matrix[y][x] = value
            function[y][x] = True

    # Finder patterns and separators
    def finder_pattern(cx, cy):
        for dy in range(-1, 8):
            for dx in range(-1, 8):
                x = cx + dx
                y = cy + dy

                if not (0 <= x < size and 0 <= y < size):
                    continue

                dark = (
                    0 <= dx <= 6
                    and 0 <= dy <= 6
                    and (
                        dx in (0, 6)
                        or dy in (0, 6)
                        or (2 <= dx <= 4 and 2 <= dy <= 4)
                    )
                )

                set_function(x, y, int(dark))

    finder_pattern(0, 0)
    finder_pattern(size - 7, 0)
    finder_pattern(0, size - 7)

    # Alignment pattern
    if version >= 2:
        cx = size - 7
        cy = size - 7

        for dy in range(-2, 3):
            for dx in range(-2, 3):
                dark = max(abs(dx), abs(dy)) != 1

                set_function(cx + dx, cy + dy, int(dark))

    # Timing patterns
    for i in range(8, size - 8):
        value = int(i % 2 == 0)

        if matrix[6][i] is None:
            set_function(i, 6, value)

        if matrix[i][6] is None:
            set_function(6, i, value)

    # Reserve format information modules
    format_positions = []

    for i in range(6):
        format_positions.append((8, i))

    format_positions.extend([
        (8, 7),
        (8, 8),
        (7, 8),
    ])

    for i in range(9, 15):
        format_positions.append((14 - i, 8))

    for i in range(8):
        format_positions.append((size - 1 - i, 8))

    for i in range(8, 15):
        format_positions.append((8, size - 15 + i))

    for x, y in format_positions:
        set_function(x, y, 0)

    # Fixed dark module
    set_function(8, size - 8, 1)

    return matrix, function


# ---------------------------------------------------------
# Format information
# ---------------------------------------------------------

def format_bits(mask):
    # Error correction level L = 01
    data = (0b01 << 3) | mask

    remainder = data

    for _ in range(10):
        remainder = (remainder << 1) ^ (
            (remainder >> 9) * 0x537
        )

    return ((data << 10) | remainder) ^ 0x5412


def add_format_information(matrix, function, mask):
    size = len(matrix)
    bits = format_bits(mask)

    positions = []

    for i in range(6):
        positions.append((8, i))

    positions.extend([
        (8, 7),
        (8, 8),
        (7, 8),
    ])

    for i in range(9, 15):
        positions.append((14 - i, 8))

    for i in range(8):
        positions.append((size - 1 - i, 8))

    for i in range(8, 15):
        positions.append((8, size - 15 + i))

    for i, (x, y) in enumerate(positions):
        value = (bits >> i) & 1

        matrix[y][x] = value
        function[y][x] = True


# ---------------------------------------------------------
# Data placement and masking
# ---------------------------------------------------------

def place_data(matrix, function, codewords):
    size = len(matrix)

    bits = []

    for byte in codewords:
        for i in reversed(range(8)):
            bits.append((byte >> i) & 1)

    index = 0
    upward = True

    right = size - 1

    while right >= 1:

        if right == 6:
            right -= 1

        for vert in range(size):
            y = size - 1 - vert if upward else vert

            for x in (right, right - 1):

                if function[y][x]:
                    continue

                value = bits[index] if index < len(bits) else 0
                index += 1

                # Mask pattern 0
                if (x + y) % 2 == 0:
                    value ^= 1

                matrix[y][x] = value

        upward = not upward
        right -= 2


# ---------------------------------------------------------
# Complete QR generation
# ---------------------------------------------------------

def generate_qr(text):
    """
    Generate a QR matrix from a string.

    Returns:
        List[List[int]]: QR matrix.
        1 = black, 0 = white.
    """

    payload = text.encode("utf-8")

    version = None

    for v, (data_capacity, _) in VERSIONS.items():

        # 4 mode bits + 8 character count bits + payload
        if len(payload) <= 255 and (
            12 + len(payload) * 8 <= data_capacity * 8
        ):
            version = v
            break

    if version is None:
        raise ValueError(
            "URL too long. Maximum supported payload: 106 bytes."
        )

    codewords = encode_data(text, version)

    matrix, function = create_matrix(version)

    place_data(matrix, function, codewords)

    # Fixed mask 0
    add_format_information(matrix, function, 0)

    return matrix


# ---------------------------------------------------------
# Terminal rendering
# ---------------------------------------------------------

def render_qr(matrix):
    """
    Render QR matrix using Unicode half-block characters.

    Uses explicit black/white terminal backgrounds,
    so both light and dark terminal themes work.
    """

    quiet = 4
    size = len(matrix)

    # Add quiet zone
    matrix = (
        [[0] * (size + quiet * 2) for _ in range(quiet)]
        +
        [
            [0] * quiet + row + [0] * quiet
            for row in matrix
        ]
        +
        [[0] * (size + quiet * 2) for _ in range(quiet)]
    )

    for y in range(0, len(matrix), 2):
        line = []

        for x in range(len(matrix)):
            top = matrix[y][x]
            bottom = matrix[y + 1][x]

            if top and bottom:
                line.append("\033[40;30m ")
            elif top:
                line.append("\033[47;30m▀")
            elif bottom:
                line.append("\033[40;37m▀")
            else:
                line.append("\033[47;37m ")

        print("".join(line) + "\033[0m")


def print_qr(text):
    """Generate and print a QR code."""

    matrix = generate_qr(text)
    render_qr(matrix)


# ---------------------------------------------------------
# CLI
# ---------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Minimal dependency-free QR generator."
    )

    parser.add_argument(
        "host",
        help="IP address, hostname, or complete URL"
    )

    parser.add_argument(
        "port",
        nargs="?",
        type=int,
        help="Port (default: 8000)"
    )

    parser.add_argument(
        "--https",
        action="store_true",
        help="Use HTTPS"
    )

    args = parser.parse_args()

    if "://" in args.host:

        if args.port is not None:
            parser.error("Do not specify a port with a complete URL.")

        url = args.host

    else:

        scheme = "https" if args.https else "http"
        port = args.port if args.port is not None else 8000

        if not 1 <= port <= 65535:
            parser.error("Port must be between 1 and 65535.")

        url = f"{scheme}://{args.host}:{port}"

    try:
        print_qr(url)
        print(f"\n{url}")

    except ValueError as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()
