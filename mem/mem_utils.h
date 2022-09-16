//  Created by Nguyen Thanh Dat on 29/8/22.
//  Copyright © 2022 Nguyen Thanh Dat. All rights reserved.
//

#ifndef mem_utils_h
#define mem_utils_h

#include <stdio.h>
#include "search_result_def.h"

void *search_mem_value(const void *b, size_t len, void *v, size_t vlen, int type, int comparison);

#endif /* mem_utils_h */
