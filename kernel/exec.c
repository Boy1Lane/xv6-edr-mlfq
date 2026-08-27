#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include "fs.h"
#include "sleeplock.h"
#include "file.h"
#include "elf.h"
#include "sha256.h"
#include "whitelist.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// Look up a binary hash in the generated whitelist (kernel/whitelist.h).
// Returns the matching index, or -1 if the binary is not whitelisted.
static int
wl_lookup(const uint8 h[32])
{
  for(int i = 0; i < WHITELIST_COUNT; i++){
    int match = 1;
    for(int j = 0; j < 32; j++){
      if(wl_hashes[i][j] != h[j]){
        match = 0;
        break;
      }
    }
    if(match)
      return i;
  }
  return -1;
}

// Compute the SHA-256 of the executable currently held locked in ip.
// Returns 0 on success, -1 on read/allocation failure.
static int
hash_inode(struct inode *ip, uint8 out[32])
{
  sha256_ctx ctx;
  char *buf;
  uint off = 0;

  if((buf = kalloc()) == 0)
    return -1;

  sha256_init(&ctx);
  while(off < ip->size){
    uint n = ip->size - off;
    if(n > PGSIZE)
      n = PGSIZE;
    if(readi(ip, 0, (uint64)buf, off, n) != n){
      kfree(buf);
      return -1;
    }
    sha256_update(&ctx, buf, n);
    off += n;
  }
  kfree(buf);
  sha256_final(&ctx, out);
  return 0;
}

// P2: verify whitelist signature generated at build time.
// Computes SHA-256(SECRET + hex(hashes)) and compares to wl_signature.
int
whitelist_verify(void)
{
  sha256_ctx ctx;
  sha256_init(&ctx);
  sha256_update(&ctx, wl_secret, strlen(wl_secret));
  for(int i = 0; i < WHITELIST_COUNT; i++){
    for(int j = 0; j < 32; j++){
      char hex[2];
      hex[0] = "0123456789abcdef"[(wl_hashes[i][j] >> 4) & 0xF];
      hex[1] = "0123456789abcdef"[wl_hashes[i][j] & 0xF];
      sha256_update(&ctx, hex, 2);
    }
  }
  uint8 out[32];
  sha256_final(&ctx, out);
  for(int i = 0; i <32; i++){
    if(out[i] != wl_signature[i]){
      printf("whitelist_verify: signature mismatch at byte %d (expected %x got %x)\n", i, wl_signature[i], out[i]);
      return -1;
    }
  }
  printf("whitelist: %d entries verified (signed)\n", WHITELIST_COUNT);
  return 0;
}

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    int perm = 0;
    if(flags & 0x1)
      perm = PTE_X;
    if(flags & 0x2)
      perm |= PTE_W;
    return perm;
}

//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
  char *s, *last;
  int i, off, wlx;
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
  uint8 binhash[32];

  begin_op();

  // Open the executable file.
  if((ip = namei(path)) == 0){
    end_op();
    return -1;
  }
  ilock(ip);

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    goto bad;

  // EDR: identify the binary by content hash while the inode is locked.
  // Fail-closed: a binary we cannot hash is simply not whitelisted.
  if(hash_inode(ip, binhash) < 0)
    wlx = -1;
  else
    wlx = wl_lookup(binhash);

  if((pagetable = proc_pagetable(p)) == 0)
    goto bad;

  // Load program into memory.
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
    if(ph.vaddr + ph.memsz < ph.vaddr)
      goto bad;
    if(ph.vaddr % PGSIZE != 0)
      goto bad;
    uint64 sz1;
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
      goto bad;
    sz = sz1;
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
  end_op();
  ip = 0;

  p = myproc();
  uint64 oldsz = p->sz;

  // Allocate some pages at the next page boundary.
  // Make the first inaccessible as a stack guard.
  // Use the rest as the user stack.
  sz = PGROUNDUP(sz);
  uint64 sz1;
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    goto bad;
  sz = sz1;
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
  sp = sz;
  stackbase = sp - USERSTACK*PGSIZE;

  // Copy argument strings into new stack, remember their
  // addresses in ustack[].
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
    sp -= strlen(argv[argc]) + 1;
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    if(sp < stackbase)
      goto bad;
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[argc] = sp;
  }
  ustack[argc] = 0;

  // push a copy of ustack[], the array of argv[] pointers.
  sp -= (argc+1) * sizeof(uint64);
  sp -= sp % 16;
  if(sp < stackbase)
    goto bad;
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    goto bad;

  // a0 and a1 contain arguments to user main(argc, argv)
  // argc is returned via the system call return
  // value, which goes in a0.
  p->trapframe->a1 = sp;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
    if(*s == '/')
      last = s+1;
  safestrcpy(p->name, last, sizeof(p->name));
    
  // EDR Authentication — hash-based (mitigates DESIGN.md L1 path spoofing).
  // Whitelist privileges attach to the exact bytes of the binary, so renaming
  // a whitelisted program no longer helps an attacker and modifying one
  // revokes the privilege.
  switch(wlx){
  case WL_IDX_INIT:
  case WL_IDX_SH:
  case WL_IDX_USERTESTS:
  case WL_IDX_FORKTEST:
    p->is_whitelisted = 1;
    break;
  default:
    p->is_whitelisted = 0;
  }
  p->edr_trusted = (wlx == WL_IDX_EDR_DAEMON) ? 1 : 0;
    
  // Commit to the user image.
  oldpagetable = p->pagetable;
  p->pagetable = pagetable;
  p->sz = sz;
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
  p->trapframe->sp = sp; // initial stack pointer
  proc_freepagetable(oldpagetable, oldsz);

  return argc; // this ends up in a0, the first argument to main(argc, argv)

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    end_op();
  }
  return -1;
}

// Load an ELF program segment into pagetable at virtual address va.
// va must be page-aligned
// and the pages from va to va+sz must already be mapped.
// Returns 0 on success, -1 on failure.
static int
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
      return -1;
  }
  
  return 0;
}
