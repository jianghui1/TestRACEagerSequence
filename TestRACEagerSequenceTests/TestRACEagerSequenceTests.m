//
//  TestRACEagerSequenceTests.m
//  TestRACEagerSequenceTests
//
//  Created by ys on 2018/8/17.
//  Copyright © 2018年 ys. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <ReactiveCocoa.h>
#import <RACEagerSequence.h>

@interface TestRACEagerSequenceTests : XCTestCase

@end

@implementation TestRACEagerSequenceTests

- (void)test_return
{
    RACEagerSequence *sequence = [RACEagerSequence return:@"x"];
    NSLog(@"return -- %@", sequence);
    
    // 打印日志：
    /*
     2018-08-17 17:50:07.949142+0800 TestRACEagerSequence[53369:18425363] return -- <RACEagerSequence: 0x604000223700>{ name = , array = (
     x
     ) }
     */
}

- (void)test_bind
{
    NSArray *array = @[@1, @3];
    RACArraySequence *arraySequence = [RACArraySequence sequenceWithArray:array offset:0];
    RACEagerSequence *eagerSequence = [RACEagerSequence sequenceWithArray:array offset:0];
    RACStreamBindBlock (^block)(void) = ^{
        return ^(id value, BOOL *stop) {
            return [RACSequence return:@"10000"];
        };
    };
    NSLog(@"bind -- %@ -- %@", [arraySequence bind:block], [eagerSequence bind:block]);
    
    // 打印日志：
    /*
     2018-08-17 17:57:46.320620+0800 TestRACEagerSequence[53678:18449077] bind -- <RACDynamicSequence: 0x600000099320>{ name = , head = (unresolved), tail = (unresolved) } -- <RACEagerSequence: 0x600000229740>{ name = , array = (
     10000,
     10000
     ) }
     */
}

- (void)test_concat
{
    RACEagerSequence *sequence1 = [RACEagerSequence sequenceWithArray:@[@1, @3] offset:0];
    RACEagerSequence *sequence2 = [RACEagerSequence sequenceWithArray:@[@2, @4] offset:1];
    NSLog(@"concat -- %@", [sequence1 concat:sequence2]);
    
    // 打印日志：
    /*
     2018-08-17 18:00:04.416837+0800 TestRACEagerSequence[53765:18456163] concat -- <RACEagerSequence: 0x600000229760>{ name = , array = (
     1,
     3,
     4
     ) }
     */
}

- (void)test_eagerSequence
{
    RACEagerSequence *sequence = [RACEagerSequence return:@(1)];
    NSLog(@"eagerSequence -- %@ -- %@", sequence, [sequence eagerSequence]);
    
    // 打印日志：
    /*
     2018-08-17 18:03:13.999872+0800 TestRACEagerSequence[53887:18465238] eagerSequence -- <RACEagerSequence: 0x604000230f60>{ name = , array = (
     1
     ) } -- <RACEagerSequence: 0x604000230f60>{ name = , array = (
     1
     ) }
     */
}

- (void)test_lazySequence
{
    RACEagerSequence *sequence = [RACEagerSequence sequenceWithArray:@[@1, @2] offset:0];
    NSLog(@"lazySequence -- %@ -- %@", sequence, [sequence lazySequence]);
    
    // 打印日志：
    /*
     2018-08-17 18:05:04.759838+0800 TestRACEagerSequence[53978:18470702] lazySequence -- <RACEagerSequence: 0x60400023cd40>{ name = , array = (
     1,
     2
     ) } -- <RACArraySequence: 0x60400023cd80>{ name = , array = (
     1,
     2
     ) }
     */
}

- (void)test_foldRightWithStart
{
    RACArraySequence *sequence = [RACArraySequence sequenceWithArray:@[@1, @2, @3] offset:0];
    NSLog(@"foldRightWithStart -- %@", [sequence foldRightWithStart:@100 reduce:^id(id first, RACSequence *rest) {
        id result;
        for (id value in [rest array]) {
            result = @([value intValue] + [result intValue]);
        }
        return @([first intValue] + [result intValue]);
    }]);
    
    // 打印日志：
    /*
     2018-08-17 18:11:50.888905+0800 TestRACEagerSequence[54231:18490439] foldRightWithStart -- 106
     */
}

@end
