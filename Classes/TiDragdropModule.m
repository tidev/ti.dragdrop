/**
 * Ti.DragDrop
 *
 * Created by Chris Bowley
 */

#import "TiDragdropModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUILabel.h"
#import "TiUITextWidget.h"
#import "TiUtils.h"
#import "TiViewProxy.h"

@implementation TiDragdropModule

#pragma mark -
#pragma mark Internal

- (id)moduleGUID
{
  return @"a67fd4a5-d226-4622-b863-cdbccfc1354b";
}

- (NSString *)moduleId
{
  return @"ti.dragdrop";
}

#pragma mark Lifecycle

- (void)startup
{
  [super startup];

  NSLog(@"[DEBUG] %@ loaded", self);
}

#pragma mark -
#pragma mark Public APIs

- (void)setDropView:(id)value
{
  _dropInteractionView = [(TiViewProxy *)value view];

  UIDropInteraction *dropInteraction = [[UIDropInteraction alloc] initWithDelegate:self];
  [_dropInteractionView addInteraction:dropInteraction];
}

- (void)enableDragOnView:(id)value
{
  ENSURE_UI_THREAD(enableDragOnView, value);
  ENSURE_SINGLE_ARG(value, TiViewProxy);

  UIView *view = [(TiViewProxy *)value view];

  UIDragInteraction *dragInteraction = [[UIDragInteraction alloc] initWithDelegate:self];
  [view addInteraction:dragInteraction];
  view.userInteractionEnabled = YES;
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
  return @[ item ];
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
  UIDropOperation operation = UIDropOperationMove;
  if (session.localDragSession == nil) {
    operation = UIDropOperationCopy;
  }
  return [[UIDropProposal alloc] initWithDropOperation:operation];
}

- (void)dropInteraction:(UIDropInteraction *)interaction performDrop:(id<UIDropSession>)session
{
  CGPoint location = [session locationInView:_dropInteractionView];

  // get first item
  NSItemProvider *itemProvider = session.items.firstObject.itemProvider;

  if ([itemProvider canLoadObjectOfClass:[UIImage class]]) {
    if (session.localDragSession == nil) {
      if (![self _hasListeners:@"imageCopied"]) {
        DebugLog(@"[ERROR] Missing \"imageCopied\" event listener while trying to copy image.");
        return;
      }
      [itemProvider loadObjectOfClass:([UIImage class])completionHandler:^(id<NSItemProviderReading> _Nullable object, NSError *_Nullable error) {
        UIImage *image = (UIImage *)object;
        TiBlob *blob = [[TiBlob alloc] initWithImage:image];
        [self fireEvent:@"imageCopied"
             withObject:@{
               @"image" : blob,
               @"location" : [[TiPoint alloc] initWithPoint:location]
             }];
      }];
    } else {
      if (![self _hasListeners:@"imageMoved"]) {
        DebugLog(@"[ERROR] Missing \"imageMoved\" event listener while trying to move image.");
        return;
      }

      [self fireEvent:@"imageMoved"
           withObject:@{
             @"location" : [[TiPoint alloc] initWithPoint:location]
           }];
    }

  } else if ([itemProvider canLoadObjectOfClass:[NSURL class]]) {
    if (session.localDragSession == nil) {
      if (![self _hasListeners:@"urlCopied"]) {
        DebugLog(@"[ERROR] Missing \"urlCopied\" event listener while trying to copy an URL.");
        return;
      }
      [itemProvider loadObjectOfClass:([NSURL class])completionHandler:^(id<NSItemProviderReading> _Nullable object, NSError *_Nullable error) {
        NSURL *URL = (NSURL *)object;
        [self fireEvent:@"urlCopied"
             withObject:@{
               @"text" : URL.absoluteString,
               @"location" : [[TiPoint alloc] initWithPoint:location]
             }];
      }];
    } else {
      if (![self _hasListeners:@"urlMoved"]) {
        DebugLog(@"[ERROR] Missing \"urlMoved\" event listener while trying to move an URL.");
        return;
      }
      [self fireEvent:@"urlMoved"
           withObject:@{
             @"location" : [[TiPoint alloc] initWithPoint:location]
           }];
    }
  } else if ([itemProvider canLoadObjectOfClass:[NSString class]]) {
    if (session.localDragSession == nil) {
      if (![self _hasListeners:@"textCopied"]) {
        DebugLog(@"[ERROR] Missing \"textCopied\" event listener while trying to copy a text.");
        return;
      }
      [itemProvider loadObjectOfClass:([NSString class])completionHandler:^(id<NSItemProviderReading> _Nullable object, NSError *_Nullable error) {
        NSString *string = (NSString *)object;
        [self fireEvent:@"textCopied"
             withObject:@{
               @"text" : string,
               @"location" : [[TiPoint alloc] initWithPoint:location]
             }];
      }];
    } else {
      if (![self _hasListeners:@"textMoved"]) {
        DebugLog(@"[ERROR] Missing \"textMoved\" event listener while trying to move a text.");
        return;
      }
      [self fireEvent:@"textMoved"
           withObject:@{
             @"location" : [[TiPoint alloc] initWithPoint:location]
           }];
    }
  }
}

@end
