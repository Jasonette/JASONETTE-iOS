//
//  DTHTMLParser.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 1/18/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTHTMLParser.h"
#import <libxml/HTMLparser.h>


@interface DTHTMLParser()

@property (nonatomic, strong) NSError *parserError;
@property (nonatomic, assign) NSStringEncoding encoding;

- (void)_resetAccumulateBufferAndReportCharacters;
- (void)_accumulateCharacters:(const xmlChar *)characters length:(int)length;

@end


#pragma mark Event function prototypes

void _startDocument(void *context);
void _endDocument(void *context);
void _startElement(void *context, const xmlChar *name,const xmlChar **atts);
void _startElement_no_delegate(void *context, const xmlChar *name, const xmlChar **atts);
void _endElement(void *context, const xmlChar *name);
void _endElement_no_delegate(void *context, const xmlChar *chars);
void _characters(void *context, const xmlChar *ch, int len);
void _comment(void *context, const xmlChar *value);
void _dterror(void *context, const char *msg, ...);
void _cdataBlock(void *context, const xmlChar *value, int len);
void _processingInstruction (void *context, const xmlChar *target, const xmlChar *data);

#pragma mark Event functions
void _startDocument(void *context)
{
	DTHTMLParser *myself = (__bridge DTHTMLParser *)context;
	
	[myself.delegate parserDidStartDocument:myself];
}

void _endDocument(void *context)
{
	DTHTMLParser *myself = (__bridge DTHTMLParser *)context;
	
	[myself.delegate parserDidEndDocument:myself];
}

void _startElement(void *context, const xmlChar *name, const xmlChar **atts)
{
	DTHTMLParser *myself = (__bridge DTHTMLParser *)context;
    
    [myself _resetAccumulateBufferAndReportCharacters];
	
	NSString *nameStr = [NSString stringWithUTF8String:(char *)name];
	
	NSMutableDictionary *attributes = nil;
	
	if (atts)
	{
		NSString *key = nil;
		NSString *value = nil;
		
		attributes = [[NSMutableDictionary alloc] init];
		
		int i = 0;
		while (1)
		{
			char *att = (char *)atts[i++];
			
			if (!key)
			{
				if (!att)
				{
					// we're done
					break;
				}
				
				key = [NSString stringWithUTF8String:att];
			}
			else
			{
				if (att)
				{
					value = [NSString stringWithUTF8String:att];
				}
				else
				{
					// solo attribute
					value = key;
				}
				
				[attributes setObject:value forKey:key];
				
				value = nil;
				key = nil;
			}
		}
	}
	
	[myself.delegate parser:myself didStartElement:nameStr attributes:attributes];
}

void _startElement_no_delegate(void *context, const xmlChar *name, const xmlChar **atts)
{
	DTHTMLParser *myself = (__bridge DTHTMLParser *)context;
    
    [myself _resetAccumulateBufferAndReportCharacters];
}

void _endElement(void *context, const xmlChar *chars)
{
	DTHTMLParser *myself = (__bridge DTHTMLParser *)context;
    
    [myself _resetAccumulateBufferAndReportCharacters];
	
	NSString *nameStr = [NSString stringWithUTF8String:(char *)chars];
	
	[myself.delegate parser:myself didEndElement:nameStr];
}

void _endElement_no_delegate(void *context, const xmlChar *chars)
{
	DTHTMLParser *myself = (__bridge DTHTMLParser *)context;
    
    [myself _resetAccumulateBufferAndReportCharacters];
}

// libxml reports characters in batches of at most 1000 at a time
// in addition, entities are reported separately
void _characters(void *context, const xmlChar *chars, int len)
{
	DTHTMLParser *myself = (__bridge DTHTMLParser *)context;
    
    [myself _accumulateCharacters:chars length:len];
}

void _comment(void *context, const xmlChar *chars)
{
	DTHTMLParser *myself = (__bridge DTHTMLParser *)context;
	
	NSString *string = [NSString stringWithCString:(const char *)chars encoding:myself.encoding];
	
	[myself.delegate parser:myself foundComment:string];
}

void _dterror(void *context, const char *msg, ...)
{
	DTHTMLParser *myself = (__bridge DTHTMLParser *)context;
	
	char string[256];
	va_list arg_ptr;
	
	va_start(arg_ptr, msg);
	vsnprintf(string, 256, msg, arg_ptr);
	va_end(arg_ptr);
	
	NSString *errorMsg = [NSString stringWithUTF8String:string];
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorMsg forKey:NSLocalizedDescriptionKey];
	myself.parserError = [NSError errorWithDomain:@"DTHTMLParser" code:1 userInfo:userInfo];
	
	[myself.delegate parser:myself parseErrorOccurred:myself.parserError];
}

void _cdataBlock(void *context, const xmlChar *value, int len)
{
	DTHTMLParser *myself = (__bridge DTHTMLParser *)context;
	
	NSData *data = [NSData dataWithBytes:(const void *)value length:len];
	
	[myself.delegate parser:myself foundCDATA:data];
}

void _processingInstruction (void *context, const xmlChar *target, const xmlChar *data)
{
	DTHTMLParser *myself = (__bridge DTHTMLParser *)context;
	
	NSStringEncoding encoding = myself.encoding;
	
	NSString *targetStr = [NSString stringWithCString:(const char *)target encoding:encoding];
	NSString *dataStr = [NSString stringWithCString:(const char *)data encoding:encoding];
	
	[myself.delegate parser:myself foundProcessingInstructionWithTarget:targetStr data:dataStr];
}

@implementation DTHTMLParser
{
	htmlSAXHandler _handler;
	
	NSData *_data;
	NSStringEncoding _encoding;
	
	DT_WEAK_VARIABLE id <DTHTMLParserDelegate> _delegate;
	htmlParserCtxtPtr _parserContext;
	
    NSMutableString *_accumulateBuffer;
	
	BOOL _isAborting;
}


- (id)initWithData:(NSData *)data encoding:(NSStringEncoding)encoding
{
	if (!data)
	{
		return nil;
	}
	
	self = [super init];
	if (self)
	{
		_data = data;
		_encoding = encoding;
		
		xmlSAX2InitHtmlDefaultSAXHandler(&_handler);
		
		// set default handlers as we would crash otherwise
		self.delegate = nil;
	}
	
	return self;
}

- (void)dealloc
{
	if (_parserContext)
	{
		htmlFreeParserCtxt(_parserContext);
	}
}

- (void)_resetAccumulateBufferAndReportCharacters
{
    if (!_accumulateBuffer.length)
    {
		// nothing in the buffer
		return;
	}
	
    [self.delegate parser:self foundCharacters:_accumulateBuffer];
	
	// reset buffer
	_accumulateBuffer = nil;
}

- (void)_accumulateCharacters:(const xmlChar *)characters length:(int)length
{
    if (!_accumulateBuffer)
    {
        _accumulateBuffer = [[NSMutableString alloc] initWithBytes:characters length:length encoding:NSUTF8StringEncoding];
    }
    else
    {
        // we don't need to use the copy version since _accumulateBuffer will copy characters immediately
        [_accumulateBuffer appendString:[[NSString alloc] initWithBytesNoCopy:(void *)characters length:length encoding:NSUTF8StringEncoding freeWhenDone:NO]];
    }
}

- (BOOL)parse
{
	void *dataBytes = (char *)[_data bytes];
	unsigned long dataSize = [_data length];
	
	// detect encoding if necessary
	xmlCharEncoding charEnc = XML_CHAR_ENCODING_NONE;
	
	if (!_encoding)
	{
		charEnc = xmlDetectCharEncoding(dataBytes, (int)dataSize);
	}
	else
	{
		// convert the encoding
		CFStringEncoding cfenc = CFStringConvertNSStringEncodingToEncoding(_encoding);
		
		if (cfenc != kCFStringEncodingInvalidId)
		{
			CFStringRef cfencstr = CFStringConvertEncodingToIANACharSetName(cfenc);
			
			if (cfencstr)
			{
				NSString *NS_VALID_UNTIL_END_OF_SCOPE encstr = [NSString stringWithString:(__bridge NSString*)cfencstr];
				const char *enc = [encstr UTF8String];
				
				charEnc = xmlParseCharEncoding(enc);
			}
		}
	}
	
	// create a parse context
	_parserContext = htmlCreatePushParserCtxt(&_handler, (__bridge void *)self, dataBytes, (int)dataSize, NULL, charEnc);
	
	// set some options
	htmlCtxtUseOptions(_parserContext, HTML_PARSE_RECOVER | HTML_PARSE_NONET | HTML_PARSE_COMPACT | HTML_PARSE_NOBLANKS);
	
	// parse!
	int result = htmlParseDocument(_parserContext);
	
	return (result==0 && !_isAborting);
}

- (void)abortParsing
{
	if (_parserContext)
	{
		// apparently this frees it too
		xmlStopParser(_parserContext);
		_parserContext = NULL;
	}
	
	_isAborting = YES;
	
	// prevent future callbacks
	_handler.startDocument = NULL;
	_handler.endDocument = NULL;
	_handler.startElement = NULL;
	_handler.endElement = NULL;
	_handler.characters = NULL;
	_handler.comment = NULL;
	_handler.error = NULL;
	_handler.processingInstruction = NULL;
	
	// inform delegate
	__strong __typeof__(_delegate) delegate = _delegate;
	if ([delegate respondsToSelector:@selector(parser:parseErrorOccurred:)])
	{
		[delegate parser:self parseErrorOccurred:self.parserError];
	}
}

#pragma mark Properties

- (id <DTHTMLParserDelegate>)delegate
{
	return _delegate;
}

- (void)setDelegate:(id <DTHTMLParserDelegate>)delegate
{
	_delegate = delegate;
	
	if ([delegate respondsToSelector:@selector(parserDidStartDocument:)])
	{
		_handler.startDocument = _startDocument;
	}
	else
	{
		_handler.startDocument = NULL;
	}
	
	if ([delegate respondsToSelector:@selector(parserDidEndDocument:)])
	{
		_handler.endDocument = _endDocument;
	}
	else
	{
		_handler.endDocument = NULL;
	}

	if ([delegate respondsToSelector:@selector(parser:foundCharacters:)])
	{
		_handler.characters = _characters;
	}
	else
	{
		_handler.characters = NULL;
	}
	
	if ([delegate respondsToSelector:@selector(parser:didStartElement:attributes:)])
	{
		_handler.startElement = _startElement;
	}
	else
	{
		// if there is a character handler we need to still report start of elements for accumulation
		if (_handler.characters)
		{
			_handler.startElement = _startElement_no_delegate;
		}
		else
		{
			_handler.startElement = NULL;
		}
	}
	
	if ([delegate respondsToSelector:@selector(parser:didEndElement:)])
	{
		_handler.endElement = _endElement;
	}
	else
	{
		// if there is a character handler we need to still report start of elements for accumulation
		if (_handler.characters)
		{
			_handler.endElement = _endElement_no_delegate;
		}
		else
		{
			_handler.endElement = NULL;
		}
	}
	
	if ([delegate respondsToSelector:@selector(parser:foundComment:)])
	{
		_handler.comment = _comment;
	}
	else
	{
		_handler.comment = NULL;
	}
	
	if ([delegate respondsToSelector:@selector(parser:parseErrorOccurred:)])
	{
		_handler.error = _dterror;
	}
	else
	{
		_handler.error = NULL;
	}
	
	if ([delegate respondsToSelector:@selector(parser:foundCDATA:)])
	{
		_handler.cdataBlock = _cdataBlock;
	}
	else
	{
		_handler.cdataBlock = NULL;
	}
	
	if ([delegate respondsToSelector:@selector(parser:foundProcessingInstructionWithTarget:data:)])
	{
		_handler.processingInstruction = _processingInstruction;
	}
	else
	{
		_handler.processingInstruction = NULL;
	}
}

- (NSInteger)lineNumber
{
	return xmlSAX2GetLineNumber(_parserContext);
}

- (NSInteger)columnNumber
{
	return xmlSAX2GetColumnNumber(_parserContext);
}

- (NSString *)systemID
{
	char *systemID = (char *)xmlSAX2GetSystemId(_parserContext);
	
	if (!systemID)
	{
		return nil;
	}
	
	return [NSString stringWithUTF8String:systemID];
}

- (NSString *)publicID
{
	char *publicID = (char *)xmlSAX2GetPublicId(_parserContext);
	
	if (!publicID)
	{
		return nil;
	}
	
	return [NSString stringWithUTF8String:publicID];
}


@synthesize parserError = _parserError;
@synthesize encoding = _encoding;


@end
