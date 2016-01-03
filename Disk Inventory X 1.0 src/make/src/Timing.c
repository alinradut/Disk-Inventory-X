#import "Timing.h"
#import <stdint.h>
#import <string.h>		// for memset()
#import <mach/mach_time.h>


uint64_t getTime() {
	return mach_absolute_time();
}


double subtractTime(uint64_t endTime, uint64_t startTime) {
	static double conversion = 0.0;
	
	uint64_t difference = endTime - startTime;
	
	if (0.0 == conversion) {
		mach_timebase_info_data_t timebase;
		kern_return_t err;
		
		memset(&timebase, 0, sizeof(timebase));
		
		err = mach_timebase_info(&timebase);
		if (err != 0) {
			return err;
		}
		
		conversion = 1e-9 * (double) timebase.numer / (double) timebase.denom;
	}
	
	return (double) difference * conversion;
}
