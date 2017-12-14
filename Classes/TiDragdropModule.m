/**
 * Ti.DragDrop
 *
 * Created by Chris Bowley
 */

#import "TiDragdropModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiViewProxy.h"
#import "TiUITextWidget.h"
#import "TiUILabel.h"

@interface TiDragdropModule ()

@property (nonatomic, strong) UIView *dropInteractionView;

@end

@implementation TiDragdropModule 

#pragma mark -
#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"a67fd4a5-d226-4622-b863-cdbccfc1354b";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"ti.dragdrop";
}

#pragma mark Lifecycle

-(void)startup
{
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];

	NSLog(@"[DEBUG] %@ loaded",self);
}

-(void)shutdown:(id)sender
{
	// this method is called when the module is being unloaded
	// typically this is during shutdown. make sure you don't do too
	// much processing here or the app will be quit forceably

	// you *must* call the superclass
	[super shutdown:sender];
}

#pragma mark -
#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
	// optionally release any resources that can be dynamically
	// reloaded once memory is available - such as caches
	[super didReceiveMemoryWarning:notification];
}

#pragma mark Listener Notifications

-(void)_listenerAdded:(NSString *)type count:(int)count
{
	if (count == 1 && [type isEqualToString:@"my_event"])
	{
		// the first (of potentially many) listener is being added
		// for event named 'my_event'
	}
}

-(void)_listenerRemoved:(NSString *)type count:(int)count
{
	if (count == 0 && [type isEqualToString:@"my_event"])
	{
		// the last listener called for event named 'my_event' has
		// been removed, we can optionally clean up any resources
		// since no body is listening at this point for that event
	}
}

#pragma mark -
#pragma mark Public APIs

- (void)setDropView:(id)value
{
    self.dropInteractionView = [(TiViewProxy *)value view];
    
    UIDropInteraction *dropInteraction = [[UIDropInteraction alloc] initWithDelegate:self];
    [self.dropInteractionView addInteraction:dropInteraction];
}

- (void)enableDragOnView:(id)value
{
    UIView *view = [(TiViewProxy *)(value[0]) view];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIDragInteraction *dragInteraction = [[UIDragInteraction alloc] initWithDelegate:self];
        [view addInteraction: dragInteraction];
        view.userInteractionEnabled = YES;
    });
}

#pragma mark -
#pragma mark Drag Interaction Delegate

- (nonnull NSArray<UIDragItem *> *)dragInteraction:(nonnull UIDragInteraction *)interaction itemsForBeginningSession:(nonnull id<UIDragSession>)session
{
    id view = (id)interaction.view;
    id proxy = [(id)view performSelector:@selector(proxy)];
    NSItemProvider *provider;
    
    if ([view isKindOfClass:[TiUITextWidget class]]) {
        NSString *string = [proxy valueForKey:@"value"];
        provider = [[NSItemProvider alloc] initWithObject:string];
    } else if ([view isKindOfClass:[TiUILabel class]]) {
        NSString *string = [[(TiUILabel *)view label] text];
        provider = [[NSItemProvider alloc] initWithObject:string];
    } else {
        TiBlob *blob = [proxy performSelector:@selector(toBlob:)];
        provider = [[NSItemProvider alloc] initWithObject:blob.image];
    }
    
    UIDragItem *item = [[UIDragItem alloc] initWithItemProvider:provider];
    item.localObject = interaction.view.accessibilityValue;
    return @[item];
}


#pragma Drop -
#pragma mark Interaction Delegate

- (BOOL)dropInteraction:(UIDropInteraction *)interaction canHandleSession:(id<UIDropSession>)session
{
    return [session canLoadObjectsOfClass:[UIImage class]]
            || [session canLoadObjectsOfClass:[NSString class]]
            || [session canLoadObjectsOfClass:[NSAttributedString class]]
            || [session canLoadObjectsOfClass:[NSURL class]];
}

- (UIDropProposal *)dropInteraction:(UIDropInteraction *)interaction sessionDidUpdate:(id<UIDropSession>)session
{
    UIDropOperation operation;
    if (session.localDragSession == nil) {
        operation = UIDropOperationCopy;
    } else {
        operation = UIDropOperationMove;
    }
    return [[UIDropProposal alloc] initWithDropOperation:operation];
}

- (void)dropInteraction:(UIDropInteraction *)interaction performDrop:(id<UIDropSession>)session
{
    CGPoint location = [session locationInView:self.dropInteractionView];

    // get first item
    NSItemProvider *itemProvider = session.items.firstObject.itemProvider;
    
    if ([itemProvider canLoadObjectOfClass:[UIImage class]]) {
        if (session.localDragSession == nil) {
            [itemProvider loadObjectOfClass:([UIImage class]) completionHandler:^(id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error) {
                UIImage *image = (UIImage *)object;
                TiBlob *blob = [[TiBlob alloc] initWithImage:image];
                [self fireEvent:@"imageCopied" withObject:@{@"image": blob, @"location": [[TiPoint alloc] initWithPoint:location]}];
            }];
        } else {
            [self fireEvent:@"imageMoved" withObject:@{@"location": [[TiPoint alloc] initWithPoint:location]}];
        }
        
    } else if ([itemProvider canLoadObjectOfClass:[NSURL class]]) {
        if (session.localDragSession == nil) {
            [itemProvider loadObjectOfClass:([NSURL class]) completionHandler:^(id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error) {
                NSURL *URL = (NSURL *)object;
                [self fireEvent:@"urlCopied" withObject:@{@"text": URL.absoluteString, @"location": [[TiPoint alloc] initWithPoint:location]}];
            }];
        } else {
            [self fireEvent:@"urlMoved" withObject:@{@"location": [[TiPoint alloc] initWithPoint:location]}];
        }
    } else if ([itemProvider canLoadObjectOfClass:[NSString class]]) {
        if (session.localDragSession == nil) {
            [itemProvider loadObjectOfClass:([NSString class]) completionHandler:^(id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error) {
                NSString *string = (NSString *)object;
                [self fireEvent:@"textCopied" withObject:@{@"text": string, @"location": [[TiPoint alloc] initWithPoint:location]}];
            }];
        } else {
            [self fireEvent:@"textMoved" withObject:@{@"location": [[TiPoint alloc] initWithPoint:location]}];
        }
    }
}

@end
