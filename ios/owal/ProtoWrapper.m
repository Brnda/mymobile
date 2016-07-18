#import "ProtoWrapper.h"

@implementation ProtoWrapper

-(id)init {
  self = [super init];
  if (self) {
    Camera *c = [[Camera alloc] init];
    NSLog(@"Created: %@", [c description]);
  }
  return self;
}

@end