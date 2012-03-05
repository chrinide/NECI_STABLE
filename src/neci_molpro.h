#ifdef MOLPRO

#ifndef DSFMT_MEXP
#define DSFMT_MEXP 19937
#endif

#define POINTER8
#define __INT64
#define DISABLE_FFTW

#ifndef HElement_t
#define HElement_t real(dp)
#endif

#if defined(_MOLCAS_MPP_) && !defined(GA_TCGMSG)
#define __SHARED_MEM
#define PARALLEL
#define CBINDMPI
#endif

#ifndef MOLPRO_f2003
#define __ISO_C_HACK
#endif

#endif /* MOLPRO */
