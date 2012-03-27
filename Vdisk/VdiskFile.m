//
//  VdiskFile.m
//  Vdisk
//
//  Created by Hao Tan on 11-12-29.
//  Copyright (c) 2011年 http://www.tanhao.me All rights reserved.
//

#import "VdiskFile.h"

@implementation VdiskFile
@synthesize isDirectory;
@synthesize isDelete;
@synthesize ID;
@synthesize name;
@synthesize path;
@synthesize fileType;
@synthesize sha1;
@synthesize dologid;
@synthesize errorCode;
@synthesize children;
@synthesize sharedPageLink;

- (void)encodeWithCoder:(NSCoder *)encoder 
{
	[encoder encodeBool:self.isDirectory forKey:@"isDirectory"];
	[encoder encodeObject:self.ID forKey:@"ID"];
	[encoder encodeObject:self.name forKey:@"name"];
	[encoder encodeObject:self.path forKey:@"path"];
	[encoder encodeObject:self.sha1 forKey:@"sha1"];
    [encoder encodeObject:self.errorCode forKey:@"errorCode"];
    [encoder encodeObject:self.sharedPageLink forKey:@"sharedPageLink"];
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (self) 
    {
		self.isDirectory = [decoder decodeBoolForKey:@"isDirectory"];
		self.ID   = [decoder decodeObjectForKey:@"ID"];
		self.name = [decoder decodeObjectForKey:@"name"];
		self.path = [decoder decodeObjectForKey:@"path"];
		self.sha1 = [decoder decodeObjectForKey:@"sha1"];
        self.errorCode = [decoder decodeObjectForKey:@"errorCode"];
        self.sharedPageLink = [decoder decodeObjectForKey:@"sharedPageLink"];
	}
	return self;
}

@end
