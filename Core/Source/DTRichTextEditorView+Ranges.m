//
//  DTRichTextEditorView+Ranges.m
//  DTRichTextEditor
//
//  Created by Oliver Drobnik on 11.04.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTRichTextEditorView+Ranges.h"

#import <DTCoreText/DTAttributedTextContentView.h>
#import <DTCoreText/NSString+Paragraphs.h>
#import <DTCoreText/DTCoreText.h>

@implementation DTRichTextEditorView (Ranges)

#pragma mark - Working with Ranges
- (BOOL)isImageAttachmentAtPosition:(UITextPosition *)position {
    /**
     URL: Here we should check all the possible location for the image, so we don't return selection rect or fire the cursor when trying to select an image using long press or double tap.
     */
    
    // Check the position one character ahead
    UITextPosition *plusOnePosition = [self positionFromPosition:position offset:1];
    UITextRange *forwardRange = [self textRangeFromPosition:position toPosition:plusOnePosition];
    NSAttributedString *forwardCharacterString = [self attributedSubstringForRange:forwardRange];

    if ([self isImageAttachmentInAttributedString:forwardCharacterString]) {
        return YES;
    }

    // Check the position one character behind
    UITextPosition *minusOnePosition = [self positionFromPosition:position offset:-1];
    UITextRange *backwardRange = [self textRangeFromPosition:minusOnePosition toPosition:position];
    NSAttributedString *backwardCharacterString = [self attributedSubstringForRange:backwardRange];

    if ([self isImageAttachmentInAttributedString:backwardCharacterString]) {
        return YES;
    }

    return NO;
}

- (BOOL)isImageAttachmentInAttributedString:(NSAttributedString *)attributedString {
    if ([attributedString length] > 0) {
        NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
        NSTextAttachment *attachment = attributes[NSAttachmentAttributeName];
        
        if ([attachment isKindOfClass:[DTImageTextAttachment class]]) {
            return YES;
        }
    }
    
    return NO;
}

- (UITextRange *)textRangeOfWordAtPosition:(UITextPosition *)position
{
    
    // URL: Check if the position is an image attachment and abort if it is
    if ([self isImageAttachmentAtPosition:position]) {
        return nil;
    }
    
	DTTextRange *forRange = (id)[[self tokenizer] rangeEnclosingPosition:position withGranularity:UITextGranularityWord inDirection:UITextStorageDirectionForward];
	DTTextRange *backRange = (id)[[self tokenizer] rangeEnclosingPosition:position withGranularity:UITextGranularityWord inDirection:UITextStorageDirectionBackward];
	
	if (forRange && backRange)
	{
		DTTextRange *newRange = [DTTextRange textRangeFromStart:[backRange start] toEnd:[backRange end]];
		return newRange;
	}
	else if (forRange)
	{
		return forRange;
	}
	else if (backRange)
	{
		return backRange;
	}
	
	// we did not get a forward or backward range, like Word!|
	DTTextPosition *previousPosition = (id)([self.tokenizer positionFromPosition:position
                                                                      toBoundary:UITextGranularityCharacter
                                                                     inDirection:UITextStorageDirectionBackward]);
	
	forRange = (id)[[self tokenizer] rangeEnclosingPosition:previousPosition withGranularity:UITextGranularityWord inDirection:UITextStorageDirectionForward];
	backRange = (id)[[self tokenizer] rangeEnclosingPosition:previousPosition withGranularity:UITextGranularityWord inDirection:UITextStorageDirectionBackward];
	
	UITextRange *retRange = nil;
	
	if (forRange && backRange)
	{
		retRange = [DTTextRange textRangeFromStart:[backRange start] toEnd:[backRange end]];
	}
	else if (forRange)
	{
		retRange = forRange;
	}
	else if (backRange)
	{
		retRange = backRange;
	}
	
	// need to extend to include the previous position
	if (retRange)
	{
		// extend this range to go up to current position
		return [DTTextRange textRangeFromStart:[retRange start] toEnd:position];
	}
	
	return nil;
}

- (UITextRange *)textRangeOfURLAtPosition:(UITextPosition *)position URL:(NSURL **)URL
{
	NSUInteger index = [(DTTextPosition *)position location];
	
	NSRange effectiveRange;
	
	NSURL *effectiveURL = [self.attributedTextContentView.layoutFrame.attributedStringFragment attribute:DTLinkAttribute atIndex:index effectiveRange:&effectiveRange];
	
	if (!effectiveURL)
	{
		return nil;
	}
	
	DTTextRange *range = [DTTextRange rangeWithNSRange:effectiveRange];
	
	if (URL)
	{
		*URL = effectiveURL;
	}
	
	return range;
}

// returns the text range containing a given string index
- (UITextRange *)textRangeOfParagraphContainingPosition:(UITextPosition *)position
{
	NSAttributedString *attributedString = self.attributedText;
	NSString *string = [attributedString string];
	
    NSRange range = [string rangeOfParagraphAtIndex:[(DTTextPosition *)position location]];
    
	DTTextRange *retRange = [DTTextRange rangeWithNSRange:range];
    
	return retRange;
}

- (UITextRange *)textRangeOfParagraphsContainingRange:(UITextRange *)range
{
    NSRange myRange = [(DTTextRange *)range NSRangeValue];
    myRange.length++;
    
    // URL: Check if the position is an image attachment and abort if it is
    /// Iterate through the range to check for image attachments
    for (NSUInteger i = myRange.location; i < NSMaxRange(myRange); i++) {
        UITextPosition *position = [self positionFromPosition:self.beginningOfDocument offset:i];
        if ([self isImageAttachmentAtPosition:position]) {
            return nil;
        }
    }
    
    // get range containing all selected paragraphs
    NSAttributedString *attributedString = self.attributedText;
    
    NSString *string = [attributedString string];
    
    NSUInteger begIndex;
    NSUInteger endIndex;
    
    [string rangeOfParagraphsContainingRange:myRange parBegIndex:&begIndex parEndIndex:&endIndex];
    myRange = NSMakeRange(begIndex, endIndex - begIndex); // now extended to full paragraphs
    
    DTTextRange *retRange = [DTTextRange rangeWithNSRange:myRange];
    
    return retRange;
}

@end
