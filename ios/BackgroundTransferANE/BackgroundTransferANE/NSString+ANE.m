//
//  NSString+ANE.m
//  BackgroundTransferANE
//
//  Created by Maciek on 24.05.2014.
//  Copyright (c) 2014 Code Latte. All rights reserved.
//

#import "NSString+ANE.h"

@implementation NSString (ANE)

-(uint8_t *)ANEString {
    return (uint8_t *)[self UTF8String];
}

@end
