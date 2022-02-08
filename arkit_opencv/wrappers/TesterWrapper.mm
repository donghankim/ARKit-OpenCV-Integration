//
//  TesterWrapper.m
//  arkit_opencv
//
//  Created by Donghan Kim on 2022/02/08.
//

#import <opencv2/opencv.hpp>
#import <Foundation/Foundation.h>
#import "TesterWrapper.h"
#import "../C++/Tester.hpp"


@implementation TesterWrapper

- (NSString *) printHello {
    TesterClass t1;
    std::string test_message = t1.printHello();
    return [NSString
            stringWithCString:test_message.c_str()
            encoding:NSUTF8StringEncoding];
}

@end
