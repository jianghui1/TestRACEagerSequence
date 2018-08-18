##### `RACEagerSequence`作为`RACArraySequence`的子类，顾名思义，就是热序列。想要知道与冷序列的区别，就看看`.m`中的方法是如何实现的。

完整测试用例[在这里](https://github.com/jianghui1/TestRACEagerSequence)。

***
    + (instancetype)return:(id)value {
    	return [[self sequenceWithArray:@[ value ] offset:0] setNameWithFormat:@"+return: %@", [value rac_description]];
    }
重写了`return:`方法，通过调用`sequenceWithArray:offset:`获取一个对象。

测试用例：

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
***

    - (instancetype)bind:(RACStreamBindBlock (^)(void))block {
    	NSCParameterAssert(block != nil);
    	RACStreamBindBlock bindBlock = block();
    	NSArray *currentArray = self.array;
    	NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:currentArray.count];
    	
    	for (id value in currentArray) {
    		BOOL stop = NO;
    		RACSequence *boundValue = (id)bindBlock(value, &stop);
    		if (boundValue == nil) break;
    
    		for (id x in boundValue) {
    			[resultArray addObject:x];
    		}
    
    		if (stop) break;
    	}
    	
    	return [[self.class sequenceWithArray:resultArray offset:0] setNameWithFormat:@"[%@] -bind:", self.name];
    }
重写`bind:`方法，里面通过`for`循环直接完成了所有的操作，最后生成了`RACEagerSequence`对象。其实这个方法就是区分冷序列与热序列的关键。

这里一旦调用`bind:`方法，生成的序列的所有序列值就已经确定了。而对于冷信号调用`bind:`方法之后，并不会做一些数据有关的操作，只有获取`head` or `tail` 的时候才开始进行数据的处理操作，确定序列的值。

测试用例：

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
***

    - (instancetype)concat:(RACSequence *)sequence {
    	NSCParameterAssert(sequence != nil);
    	NSCParameterAssert([sequence isKindOfClass:RACSequence.class]);
    
    	NSArray *array = [self.array arrayByAddingObjectsFromArray:sequence.array];
    	return [[self.class sequenceWithArray:array offset:0] setNameWithFormat:@"[%@] -concat: %@", self.name, sequence];
    }
重写`concat:`方法，直接进行数据的拼接操作。

测试用例：

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
***

    - (RACSequence *)eagerSequence {
    	return self;
    }
返回自身，自身就是一个热序列。

测试用例：

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
***
     - (RACSequence *)lazySequence {
    	return [RACArraySequence sequenceWithArray:self.array offset:0];
    }
返回`RACArraySequence`对象，即冷序列。

测试用例：

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
***
    - (id)foldRightWithStart:(id)start reduce:(id (^)(id, RACSequence *rest))reduce {
    	return [super foldRightWithStart:start reduce:^(id first, RACSequence *rest) {
    		return reduce(first, rest.eagerSequence);
    	}];
    }
重写`foldRightWithStart:reduce:`方法，将从父类中获取的`RACSequence`对象调用`eagerSequence`方法转换成热序列，保证这个方法中所有涉及到的序列都是热序列。

测试用例：

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

***

##### 所以这个类就是一个热序列，通过`bind:`方法保证数据的操作立即执行。

到这里已经把`RACSequence`相关的类全部分析完了，上面的测试用例也全部可以在[github](https://github.com/jianghui1?tab=repositories)上找到。
