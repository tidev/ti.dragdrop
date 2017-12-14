/**
 * Ti.DragDrop
 *
 * Created by Chris Bowley
 */

#import "TiModule.h"

@interface TiDragdropModule : TiModule <UIDragInteractionDelegate, UIDropInteractionDelegate>
{
}

- (void)setDropView:(id)value;

- (void)enableDragOnView:(id)value;

@end
