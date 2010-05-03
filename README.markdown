# DESCRIPTION

EXPERIMENTAL! I am not entirely sure whether it is fully XML compliant.

This is a customized version of topfunky's Hpple.

# AUTHOR

Geoffrey Grosenbach, Christian Ziegler, [Topfunky Corporation](http://topfunky.com) and [PeepCode Screencasts](http://peepcode.com).

# FEATURES

* Easy searching by XPath
* Parses HTML and XML
* Easy access to tag content, name, and attributes via dot-notation

# INSTALLATION

* Open your XCode project and the Hpple project.
* Drag the "Hpple" directory to your project.
* Add the libxml2.2.dylib framework to your project and search paths as described at [Cocoa with Love](http://cocoawithlove.com/2008/10/using-libxml2-for-parsing-and-xpath.html)

For usage only the following classes are needed:
* TFHpple.m/.h
* TFHppleElement.m/.h
* XPathQuery.m/.h

# USAGE

See TFHppleHTMLTest.m in the Hpple project for samples.

<pre>
#import "TFHpple.h"

NSData  * data      = [NSData dataWithContentsOfFile:@"index.html"];

TFHpple * doc       = [[TFHpple alloc] initWithHTMLData:data];
NSArray * elements  = [doc search:@"//a[@class='sponsor']"];

TFHppleElement * element = [elements objectAtIndex:0];
e.content;              // The text surounded by the tag
e.name;              	// "a"
e.attributes;           // NSDictionary containing TFHppleElements for the attributes
e.childNodes;		// NSDictionary containing TFHppleElements for the childNodes

// If you need the value of the href attribute you access it like this
NSString * value = [e valueForKeyPath:@"attributes.href.content"];

</pre>
