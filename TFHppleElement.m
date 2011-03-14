//
//  TFHppleElement.m
//  Hpple
//
//  Created by Geoffrey Grosenbach on 1/31/09.
//
//  Copyright (c) 2009 Topfunky Corporation, http://topfunky.com
//
//  MIT LICENSE
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#import "TFHppleElement.h"

@implementation TFHppleElement

@synthesize name;
@synthesize content;
@synthesize attributes;
@synthesize childNodes;

- (BOOL) isTextNode {
    return [@"text" isEqualToString: name];
}

- (void) dealloc {
    [name release];
	name = nil;
    
    [content release];
	content= nil;
    
    [attributes release];
	attributes = nil;
    
    [childNodes release];
	childNodes = nil;
    
	[super dealloc];
}

- (NSArray *) childNodesWithTagName: (NSString *)tagName {
    NSPredicate *searchCriteria = [NSPredicate predicateWithFormat: @"name = %@", tagName];
    return [self childNodesWithCriteria: searchCriteria];
}

- (NSArray *) childNodesWithCriteria: (NSPredicate *)searchCriteria {
    return [childNodes filteredArrayUsingPredicate: searchCriteria];
}

- (id) valueForKeyPath: (NSString *)keyPath {
    NSArray *keys = [keyPath componentsSeparatedByString: @"."];
    int numKeys = [keys count];
    if (numKeys == 1) {
        return [super valueForKeyPath: keyPath];
    } else {
        id result = nil;
        
        if ([[keys objectAtIndex: 0] isEqualToString: @"childNodes"]) {
            NSString *key = [keys objectAtIndex: 1];
            NSUInteger index = 0;
            NSRange r;
            NSString *regEx = @"\[[0-9]+]";
            r = [key rangeOfString: regEx options: NSRegularExpressionSearch];
            if (r.location != NSNotFound) {
                NSLog(@"index %@", [key substringWithRange: r]);
                index = [[key substringWithRange: r] intValue];
                key = [key substringWithRange: NSMakeRange(0, r.location - 1)];
                result = [[self childNodesWithTagName: key] objectAtIndex: index];
            } else {
                NSLog(@"Not found.");
                result = [self childNodesWithTagName: key];
            }
            
            if (numKeys > 2) {
                NSString *subKeyPath = [[keys subarrayWithRange: NSMakeRange(2, numKeys - 2)] componentsJoinedByString: @"."];
                result = [result valueForKeyPath: subKeyPath];
            }
            
        } else {
            result = [super valueForKeyPath: keyPath];
        }
        
        return result;
    }
}


- (id)description {
	NSString *description = [NSString stringWithFormat:@"<Name: %@, Content: %@, Attributes: %@, ChildNodes: %@>", name, content, attributes, childNodes];
	return description;
}


@end