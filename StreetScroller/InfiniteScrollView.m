/*
     File: InfiniteScrollView.m
 Abstract: This view tiles UILabel instances to give the effect of infinite scrolling side to side.
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import "InfiniteScrollView.h"

@interface InfiniteScrollView () {
    NSMutableArray *visibleLabels;
    UIView         *labelContainerView;
    NSMutableArray *labels;
}

- (void)tileLabelsFromMinX:(CGFloat)minimumVisibleX toMaxX:(CGFloat)maximumVisibleX;

@end


@implementation InfiniteScrollView

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        self.contentSize = CGSizeMake(5000, self.frame.size.height);
        
        visibleLabels = [[NSMutableArray alloc] init];
        
        labelContainerView = [[UIView alloc] init];
        labelContainerView.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height/2);
        [self addSubview:labelContainerView];

        [labelContainerView setUserInteractionEnabled:NO];
        
        // hide horizontal scroll indicator so our recentering trick is not revealed
        [self setShowsHorizontalScrollIndicator:YES];
        
        labels = [[NSMutableArray alloc]init];
        for( int i=0; i<10; i++ ){
            UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 80)] autorelease];
            [label setNumberOfLines:3];
            [label setText:[NSString stringWithFormat:
                            @"1024 Block Street\nShaffer, CA\n%d",i]];
            [labels addObject:label];
        }
    }
    return self;
}

#pragma mark -
#pragma mark Layout

// Viewをごっそり移動させる
// recenter content periodically to achieve impression of infinite scrolling
- (void)recenterIfNecessary {
    CGPoint currentOffset = [self contentOffset];
    CGFloat contentWidth = [self contentSize].width;
    CGFloat centerOffsetX = (contentWidth - [self bounds].size.width) / 2.0;
    CGFloat distanceFromCenter = fabs(currentOffset.x - centerOffsetX);
    
    if (distanceFromCenter > (contentWidth / 4.0)) {
        self.contentOffset = CGPointMake(centerOffsetX, currentOffset.y);
        
        // move content by the same amount so it appears to stay still
        for (UIView *view in visibleLabels) {
            CGPoint center = [labelContainerView convertPoint:view.center toView:self];
            center.x += (centerOffsetX - currentOffset.x);
            view.center = [self convertPoint:center toView:labelContainerView];
        }
    }
}

- (void)layoutSubviews {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    [super layoutSubviews];
    
    [self recenterIfNecessary];
 
    // tile content in visible bounds
    CGRect visibleBounds = [self convertRect:[self bounds] toView:labelContainerView];
    CGFloat minimumVisibleX = CGRectGetMinX(visibleBounds);
    CGFloat maximumVisibleX = CGRectGetMaxX(visibleBounds);
    
    [self tileLabelsFromMinX:minimumVisibleX toMaxX:maximumVisibleX];
}


#pragma mark -
#pragma mark Label Tiling


- (UIView *)createLabel {
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 80)] autorelease];
    [label setNumberOfLines:3];
    [label setText:@"1024 Block Street\nShaffer, CA\n95014"];
    
    return label;
}

//- (CGFloat)placeNewLabelOnRight:(CGFloat)rightEdge {
//    UIView *label = [self createLabel];
//    [labelContainerView addSubview:label];
//    [visibleLabels addObject:label]; // add rightmost label at the end of the array
//    
//    CGRect frame = [label frame];
//    frame.origin.x = rightEdge;
//    frame.origin.y = [labelContainerView bounds].size.height - frame.size.height;
//    [label setFrame:frame];
//        
//    return CGRectGetMaxX(frame);
//}

//- (CGFloat)placeNewLabelOnLeft:(CGFloat)leftEdge {
//    UIView *label = [self createLabel];
//    [labelContainerView addSubview:label];
//    [visibleLabels insertObject:label atIndex:0]; // add leftmost label at the beginning of the array
//    
//    CGRect frame = [label frame];
//    frame.origin.x = leftEdge - frame.size.width;
//    frame.origin.y = [labelContainerView bounds].size.height - frame.size.height;
//    [label setFrame:frame];
//    
//    return CGRectGetMinX(frame);
//}

// 個々のViewを追加/削除している。
- (void)tileLabelsFromMinX:(CGFloat)minimumVisibleX toMaxX:(CGFloat)maximumVisibleX {
    // the upcoming tiling logic depends on there already being at least one label in the visibleLabels array, so
    // to kick off the tiling we need to make sure there's at least one label
    if ([visibleLabels count] == 0) {
//        [self placeNewLabelOnRight:minimumVisibleX];
        UIView *label = [self createLabel];
        [labelContainerView addSubview:label];
        [visibleLabels addObject:label]; // add rightmost label at the end of the array
        
        CGRect frame = [label frame];
        frame.origin.x = minimumVisibleX;
        frame.origin.y = [labelContainerView bounds].size.height - frame.size.height;
        [label setFrame:frame];
    }
    
    // 空いた場所にlabelを追加（右側）
    UILabel *lastLabel = [visibleLabels lastObject];
    CGFloat rightEdge = CGRectGetMaxX([lastLabel frame]);
    while (rightEdge < maximumVisibleX) {
//        rightEdge = [self placeNewLabelOnRight:rightEdge];
        UIView *label = [self createLabel];
        [labelContainerView addSubview:label];
        [visibleLabels addObject:label]; // add rightmost label at the end of the array
        
        CGRect frame = [label frame];
        frame.origin.x = rightEdge;
        frame.origin.y = [labelContainerView bounds].size.height - frame.size.height;
        [label setFrame:frame];
        rightEdge =  CGRectGetMaxX(frame);

    }
    
    // 空いた場所にlabelを追加（左側）
    UILabel *firstLabel = [visibleLabels objectAtIndex:0];
    CGFloat leftEdge = CGRectGetMinX([firstLabel frame]);
    while (leftEdge > minimumVisibleX) {
//        leftEdge = [self placeNewLabelOnLeft:leftEdge];
        UIView *label = [self createLabel];
        [labelContainerView addSubview:label];
        [visibleLabels insertObject:label atIndex:0]; // add leftmost label at the beginning of the array
        
        CGRect frame = [label frame];
        frame.origin.x = leftEdge - frame.size.width;
        frame.origin.y = [labelContainerView bounds].size.height - frame.size.height;
        [label setFrame:frame];
        
        leftEdge = CGRectGetMinX(frame);
    }
    
    // 右側からはみ出したlabelを削除
    lastLabel = [visibleLabels lastObject];
    while ([lastLabel frame].origin.x > maximumVisibleX) {
        [lastLabel removeFromSuperview];
        [visibleLabels removeLastObject];
        lastLabel = [visibleLabels lastObject];
    }
    
    // 左側からはみ出したlabelを削除
    firstLabel = [visibleLabels objectAtIndex:0];
    while (CGRectGetMaxX([firstLabel frame]) < minimumVisibleX) {
        [firstLabel removeFromSuperview];
        [visibleLabels removeObjectAtIndex:0];
        firstLabel = [visibleLabels objectAtIndex:0];
    }
}

@end
