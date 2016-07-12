/* md5.h */

#if defined(__linux__) && defined(__KERNEL__)
#  include <linux/types.h>
#  include <linux/linkage.h>
#else 
#  include <sys/types.h>
#endif

#if defined(__linux__) && defined(__KERNEL__) && (defined(X86_ASM) || defined(AMD64_ASM))
 asmlinkage
#endif
extern void md5_transform_CPUbyteorder(u_int32_t *, u_int32_t const *);

#if defined(__linux__) && defined(__KERNEL__) && (defined(X86_ASM) || defined(AMD64_ASM))
 asmlinkage
#endif
extern void md5_transform_CPUbyteorder_2x(u_int32_t *, u_int32_t const *, u_int32_t const *);
