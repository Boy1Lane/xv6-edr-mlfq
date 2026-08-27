// SHA-256 (FIPS 180-4), freestanding implementation for the xv6 kernel.
// Used by the EDR subsystem to verify binary identity at exec-time,
// replacing the spoofable path-based whitelist.

typedef struct sha256_ctx {
  uint32 state[8];
  uint64 bitlen;
  uint8  data[64];
  uint   datalen;
} sha256_ctx;

void sha256_init(sha256_ctx *ctx);
void sha256_update(sha256_ctx *ctx, const void *data, uint len);
void sha256_final(sha256_ctx *ctx, uint8 out[32]);
