//
//  XPathQuery.m
//  FuelFinder
//
//  Created by Matt Gallagher on 4/08/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
//  Changed by Christian Ziegler
//

#import "XPathQuery.h"
#import "TFHppleElement.h"

#import <libxml/tree.h>
#import <libxml/parser.h>
#import <libxml/HTMLparser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

TFHppleElement *HppleElementForNode(xmlNodePtr currentNode, TFHppleElement *parentElement) {
	
	TFHppleElement *currentElement = [[TFHppleElement new] autorelease];
	
	if (currentNode->name) {
		currentElement.name = [NSString stringWithCString:(const char *)currentNode->name encoding:NSUTF8StringEncoding];
	}
	
	if (currentNode->content && currentNode->content != (xmlChar *)-1) {
		
		NSString *content = [NSString stringWithCString:(const char *)currentNode->content encoding:NSUTF8StringEncoding];
		
		/* If tag name is text and there is a parent then it actually is content of the parent.
		 * Otherwise it must be a childNode which is why this should always be true */
		assert([currentElement.name isEqual:@"text"] && parentElement);
		
		content = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if (content.length > 0) {
			if (parentElement.content) {
				NSString *toAppend = [NSString stringWithFormat:@"\n%@", content];
				content = [parentElement.content stringByAppendingString:toAppend];
			}
			parentElement.content = content;
		}
		return nil;
	}
	
	xmlAttr *attribute = currentNode->properties;
	while (attribute) {
		// Create element and set its name
		TFHppleElement *attributeElement = [TFHppleElement new];
		attributeElement.name = [NSString stringWithCString:(const char *)attribute->name encoding:NSUTF8StringEncoding];
		
		
		// Children can be as simple as text but also complex data structures (XML) I guess :)
		if (attribute->children) {
			TFHppleElement *attributeValue = HppleElementForNode(attribute->children, attributeElement);
			if (attributeValue) {
				/* TODO: Create childNodes dictionary and stuff but not sure whether this is
				 * neccessary. Probably only for XML. Usually 'children' is only text which is
				 * then saved into content of the attribute itself */
				NSLog(@"OMG! There is a more complex structure!!!");
				assert(NO);
			}
			// TODO: Is there always only one child??
			xmlNode *child = attribute->children->next;
			if (child) {
				NSLog(@"OH OH!! Obviously there can be more than one child");
				assert(NO);
			}
		}
		
		if (!currentElement.attributes) {
			currentElement.attributes = [NSMutableDictionary dictionary];
		}
		
		NSString *key;
		id valueForTag = [currentElement.attributes valueForKey:attributeElement.name];
		// Key taken
		if (valueForTag) {
			NSNumber *numberOfElements;
			// Not a number means there is only one element with the given name so far
			if (![valueForTag isKindOfClass:NSNumber.class]) {
				numberOfElements = [NSNumber numberWithInteger:1];
				[currentElement.attributes setValue:numberOfElements forKey:attributeElement.name];
				key = [NSString stringWithFormat:@"%@[%d]", attributeElement.name, numberOfElements.integerValue];
				[currentElement.attributes setValue:valueForTag forKey:key];
			}
			else {
				numberOfElements = (NSNumber *) valueForTag;
			}
			numberOfElements = [NSNumber numberWithInteger:numberOfElements.integerValue + 1];
			[currentElement.attributes setValue:numberOfElements forKey:attributeElement.name];
			// Create key of new value with format <tagName>[#] and set the value
			key = [NSString stringWithFormat:@"%@[%d]", attributeElement.name, numberOfElements.integerValue];
		}
		// Key not taken
		else {
			key = attributeElement.name;
		}
		[currentElement.attributes setValue:attributeElement forKey:key];
		[attributeElement release];
		attribute = attribute->next;
	}
	
	xmlNodePtr childNode = currentNode->children;
	while (childNode) {
		TFHppleElement *childElement = HppleElementForNode(childNode, currentElement);
		
		if (childElement) {
			if (!currentElement.childNodes) {
				currentElement.childNodes = [NSMutableDictionary dictionary];
			}
			
			NSString *key;
			id valueForTag = [currentElement.childNodes valueForKey:childElement.name];
			// Key taken
			if (valueForTag) {
				NSNumber *numberOfElements;
				// Not a number means there is only one element with the given name so far
				if (![valueForTag isKindOfClass:NSNumber.class]) {
					numberOfElements = [NSNumber numberWithInteger:1];
					key = [NSString stringWithFormat:@"%@[%d]", childElement.name, numberOfElements.integerValue];
					[currentElement.childNodes setValue:valueForTag forKey:key];
					[currentElement.childNodes setValue:numberOfElements forKey:childElement.name];
				}
				else {
					numberOfElements = (NSNumber *) valueForTag;
				}
				numberOfElements = [NSNumber numberWithInteger:(numberOfElements.integerValue + 1)];
				[currentElement.childNodes setValue:numberOfElements forKey:childElement.name];
				// Create key of new value with format <tagName>[#] and set the value
				key = [NSString stringWithFormat:@"%@[%d]", childElement.name, numberOfElements.integerValue];
			}
			// Key not taken
			else {
				key = childElement.name;
			}
			[currentElement.childNodes setValue:childElement forKey:key];
		}
		childNode = childNode->next;
	}
	return currentElement;
}

NSArray *PerformXPathQuery(xmlDocPtr doc, NSString *query) {
	xmlXPathContextPtr xpathCtx;
	xmlXPathObjectPtr xpathObj;
	
	/* Create xpath evaluation context */
	xpathCtx = xmlXPathNewContext(doc);
	if(xpathCtx == NULL) {
		NSLog(@"Unable to create XPath context.");
		return nil;
	}
	
	/* Evaluate xpath expression */
	xpathObj = xmlXPathEvalExpression((xmlChar *)[query cStringUsingEncoding:NSUTF8StringEncoding], xpathCtx);
	if(xpathObj == NULL) {
		NSLog(@"Unable to evaluate XPath.");
		return nil;
	}
	
	xmlNodeSetPtr nodes = xpathObj->nodesetval;
	if (!nodes) {
		NSLog(@"Nodes was nil.");
		return nil;
	}
	
	NSMutableArray *resultNodes = [NSMutableArray array];
	for (NSInteger i = 0; i < nodes->nodeNr; i++) {
		
		TFHppleElement *nodeElement = HppleElementForNode(nodes->nodeTab[i], nil);
		
		if (nodeElement) {
			[resultNodes addObject:nodeElement];
		}
	}
	
	/* Cleanup */
	xmlXPathFreeObject(xpathObj);
	xmlXPathFreeContext(xpathCtx);
	
	return resultNodes;
}

NSArray *PerformHTMLXPathQuery(NSData *document, NSString *query) {
	
	xmlDocPtr doc;
	
	/* Load XML document */
	doc = htmlReadMemory([document bytes], [document length], "", NULL, HTML_PARSE_NOWARNING | HTML_PARSE_NOERROR);
	
	if (doc == NULL)
	 {
		NSLog(@"Unable to parse.");
		return nil;
	 }
	
	NSArray *result = PerformXPathQuery(doc, query);
	xmlFreeDoc(doc);
	
	return result;
}

NSArray *PerformXMLXPathQuery(NSData *document, NSString *query)
{
	xmlDocPtr doc;
	
	/* Load XML document */
	doc = xmlReadMemory([document bytes], [document length], "", NULL, XML_PARSE_RECOVER);
	
	if (doc == NULL)
	 {
		NSLog(@"Unable to parse.");
		return nil;
	 }
	
	NSArray *result = PerformXPathQuery(doc, query);
	xmlFreeDoc(doc);
	
	return result;
}
