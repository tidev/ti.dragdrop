/**
 * Ti.DragDrop
 *
 * Created by Chris Bowley
 */

#import "TiModule.h"

@interface TiDragdropModule : TiModule <UIDragInteractionDelegate, UIDropInteractionDelegate> {
  UIView *_dropInteractionView;
}

- (void)setDropView:(id)value;

- (void)enableDragOnView:(id)value;

@end
