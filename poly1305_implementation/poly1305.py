class Poly1305:
    BLOCK_SIZE = 16

    def __init__(self):
        self.key_r = [0] * 5
        self.acc = [0] * 5
        self.pad = [0] * 4
        self.extra_bytes = 0
        self.temp_buf = bytearray(self.BLOCK_SIZE)
        self.is_final_block = False

    @staticmethod
    def to_word(data, start=0):
        return (
            (data[start + 0] & 0xff) |
            ((data[start + 1] & 0xff) << 8) |
            ((data[start + 2] & 0xff) << 16) |
            ((data[start + 3] & 0xff) << 24)
        ) & 0xffffffff

    @staticmethod
    def to_bytes4(val):
        return bytes([
            val & 0xff,
            (val >> 8) & 0xff,
            (val >> 16) & 0xff,
            (val >> 24) & 0xff
        ])

    def init(self, key):

        if len(key) != 32:
            raise ValueError("Key must be exactly 32 bytes")

        self.key_r[0] = (self.to_word(key, 0)) & 0x3ffffff
        self.key_r[1] = (self.to_word(key, 3) >> 2) & 0x3ffff03
        self.key_r[2] = (self.to_word(key, 6) >> 4) & 0x3ffc0ff
        self.key_r[3] = (self.to_word(key, 9) >> 6) & 0x3f03fff
        self.key_r[4] = (self.to_word(key, 12) >> 8) & 0x00fffff

        self.acc = [0] * 5

        self.pad[0] = self.to_word(key, 16)
        self.pad[1] = self.to_word(key, 20)
        self.pad[2] = self.to_word(key, 24)
        self.pad[3] = self.to_word(key, 28)

        self.extra_bytes = 0
        self.is_final_block = False

    def process_blocks(self, msg, start, length):
        hibit = 0 if self.is_final_block else (1 << 24)

        r0 = self.key_r[0]
        r1 = self.key_r[1]
        r2 = self.key_r[2]
        r3 = self.key_r[3]
        r4 = self.key_r[4]

        s1 = r1 * 5
        s2 = r2 * 5
        s3 = r3 * 5
        s4 = r4 * 5

        h0 = self.acc[0]
        h1 = self.acc[1]
        h2 = self.acc[2]
        h3 = self.acc[3]
        h4 = self.acc[4]

        idx = start
        while length >= self.BLOCK_SIZE:
            h0 += (self.to_word(msg, idx)) & 0x3ffffff
            h1 += (self.to_word(msg, idx + 3) >> 2) & 0x3ffffff
            h2 += (self.to_word(msg, idx + 6) >> 4) & 0x3ffffff
            h3 += (self.to_word(msg, idx + 9) >> 6) & 0x3ffffff
            h4 += (self.to_word(msg, idx + 12) >> 8) | hibit

            d0 = (h0 * r0) + (h1 * s4) + (h2 * s3) + (h3 * s2) + (h4 * s1)
            d1 = (h0 * r1) + (h1 * r0) + (h2 * s4) + (h3 * s3) + (h4 * s2)
            d2 = (h0 * r2) + (h1 * r1) + (h2 * r0) + (h3 * s4) + (h4 * s3)
            d3 = (h0 * r3) + (h1 * r2) + (h2 * r1) + (h3 * r0) + (h4 * s4)
            d4 = (h0 * r4) + (h1 * r3) + (h2 * r2) + (h3 * r1) + (h4 * r0)

            carry = d0 >> 26
            h0 = d0 & 0x3ffffff
            d1 += carry

            carry = d1 >> 26
            h1 = d1 & 0x3ffffff
            d2 += carry

            carry = d2 >> 26
            h2 = d2 & 0x3ffffff
            d3 += carry

            carry = d3 >> 26
            h3 = d3 & 0x3ffffff
            d4 += carry

            carry = d4 >> 26
            h4 = d4 & 0x3ffffff
            h0 += carry * 5

            carry = h0 >> 26
            h0 = h0 & 0x3ffffff
            h1 += carry

            idx += self.BLOCK_SIZE
            length -= self.BLOCK_SIZE

        self.acc[0] = h0
        self.acc[1] = h1
        self.acc[2] = h2
        self.acc[3] = h3
        self.acc[4] = h4

    def update(self, data):

        if not isinstance(data, (bytes, bytearray)):
            data = bytes(data)

        remaining = len(data)
        offset = 0

        if self.extra_bytes:
            need = self.BLOCK_SIZE - self.extra_bytes
            if need > remaining:
                need = remaining

            for i in range(need):
                self.temp_buf[self.extra_bytes + i] = data[offset + i]

            remaining -= need
            offset += need
            self.extra_bytes += need

            if self.extra_bytes < self.BLOCK_SIZE:
                return

            self.process_blocks(self.temp_buf, 0, self.BLOCK_SIZE)
            self.extra_bytes = 0

        if remaining >= self.BLOCK_SIZE:
            need = remaining & ~(self.BLOCK_SIZE - 1)
            self.process_blocks(data, offset, need)
            offset += need
            remaining -= need

        if remaining:
            for i in range(remaining):
                self.temp_buf[self.extra_bytes + i] = data[offset + i]
            self.extra_bytes += remaining

    def finish(self):
        if self.extra_bytes:
            i = self.extra_bytes
            self.temp_buf[i] = 1
            i += 1
            while i < self.BLOCK_SIZE:
                self.temp_buf[i] = 0
                i += 1
            self.is_final_block = True
            self.process_blocks(self.temp_buf, 0, self.BLOCK_SIZE)

        h0 = self.acc[0]
        h1 = self.acc[1]
        h2 = self.acc[2]
        h3 = self.acc[3]
        h4 = self.acc[4]

        carry = h1 >> 26
        h1 = h1 & 0x3ffffff
        h2 += carry

        carry = h2 >> 26
        h2 = h2 & 0x3ffffff
        h3 += carry

        carry = h3 >> 26
        h3 = h3 & 0x3ffffff
        h4 += carry

        carry = h4 >> 26
        h4 = h4 & 0x3ffffff
        h0 += carry * 5

        carry = h0 >> 26
        h0 = h0 & 0x3ffffff
        h1 += carry

        carry = h1 >> 26
        h1 = h1 & 0x3ffffff
        h2 += carry

        carry = h2 >> 26
        h2 = h2 & 0x3ffffff
        h3 += carry

        carry = h3 >> 26
        h3 = h3 & 0x3ffffff
        h4 += carry

        carry = h4 >> 26
        h4 = h4 & 0x3ffffff
        h0 += carry * 5

        carry = h0 >> 26
        h0 = h0 & 0x3ffffff
        h1 += carry

        g0 = h0 + 5
        carry = g0 >> 26
        g0 &= 0x3ffffff

        g1 = h1 + carry
        carry = g1 >> 26
        g1 &= 0x3ffffff

        g2 = h2 + carry
        carry = g2 >> 26
        g2 &= 0x3ffffff

        g3 = h3 + carry
        carry = g3 >> 26
        g3 &= 0x3ffffff

        g4 = h4 + carry - (1 << 26)

        g4_signed = g4 if g4 < (1 << 31) else g4 - (1 << 32)
        mask = (g4_signed >> 31) & 0xffffffff
        mask = (~mask) & 0xffffffff

        h0 = (h0 & ~mask) | (g0 & mask)
        h1 = (h1 & ~mask) | (g1 & mask)
        h2 = (h2 & ~mask) | (g2 & mask)
        h3 = (h3 & ~mask) | (g3 & mask)
        h4 = (h4 & ~mask) | (g4 & mask)

        h0 = ((h0) | (h1 << 26)) & 0xffffffff
        h1 = ((h1 >> 6) | (h2 << 20)) & 0xffffffff
        h2 = ((h2 >> 12) | (h3 << 14)) & 0xffffffff
        h3 = ((h3 >> 18) | (h4 << 8)) & 0xffffffff

        total = (h0 & 0xffffffff) + (self.pad[0] & 0xffffffff)
        h0 = total & 0xffffffff

        total = (h1 & 0xffffffff) + (self.pad[1] & 0xffffffff) + (total >> 32)
        h1 = total & 0xffffffff

        total = (h2 & 0xffffffff) + (self.pad[2] & 0xffffffff) + (total >> 32)
        h2 = total & 0xffffffff

        total = (h3 & 0xffffffff) + (self.pad[3] & 0xffffffff) + (total >> 32)
        h3 = total & 0xffffffff

        tag = bytearray(16)
        tag[0:4] = self.to_bytes4(h0)
        tag[4:8] = self.to_bytes4(h1)
        tag[8:12] = self.to_bytes4(h2)
        tag[12:16] = self.to_bytes4(h3)

        return bytes(tag)


def poly1305_auth(message, key):
    p = Poly1305()
    p.init(key)
    p.update(message)
    return p.finish()


if __name__ == "__main__":

    key = bytes.fromhex("85d6be7857556d337f4452fe42d506a80103808afb0db2fd4abff6af4149f51b")
    msg = bytes.fromhex("43727970746f6772617068696320466f72756d2052657365617263682047726f7570")

    mac = poly1305_auth(msg, key)

    print("Computed MAC:", mac.hex())

    p2 = Poly1305()
    p2.init(key)
    p2.update(msg[:30])
    p2.update(msg[30:])
    mac2 = p2.finish()

    print("\nIncremental MAC:", mac2.hex())
