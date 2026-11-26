#include <mach/mach_types.h>
kern_return_t Lenovo83ALDmic_start(kmod_info_t *ki, void *data) { return KERN_SUCCESS; }
kern_return_t Lenovo83ALDmic_stop(kmod_info_t *ki, void *data) { return KERN_SUCCESS; }
KMOD_EXPLICIT_DECL(com.tarekwasfy.Lenovo83ALDmic, "0.1.0", Lenovo83ALDmic_start, Lenovo83ALDmic_stop)
