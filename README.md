# Ti.DragDrop
Use iOS 11 drag and drop interactions in Appcelerator Titanium.

## Requirements
- [x] Ti SDK 7.0.0+
- [x] iOS 11+

## Getting started
Example app project available here: https://github.com/appcelerator-developer-relations/dragdrop.

Add the module to your Titanium app project Tiapp.xml file:
```xml
<modules>
  <module>ti.dragdrop</module>
</modules>
```
Import the module in your controller:
```
var DragDrop = require('ti.dragdrop');
```js
Enabled drop interaction on target View or Window and drag interaction on View:
```
// Enable drop interaction on window
DragDrop.setDropView($.window);

// Enable drag interaction on image view
DragDrop.enableDragOnView($.imageView);
```
Handle inter-app drag in event:
```js
DragDrop.addEventListener('imageCopied', function(e) {
  var aspect = e.image.height / e.image.width;
  var width = 200;
  var height = width * aspect;

  var imageView = Ti.UI.createImageView({
    top: e.location.y - (height / 2),
    left: e.location.x - (width / 2),
    width: width,
    height: height,
    image: e.image
  });

  imageView.addEventListener('touchstart', draggableViewTouchStart);
  $.window.add(imageView);
  DragDrop.enableDragOnView(imageView);
});

function draggableViewTouchStart(e) {
  _draggingView = e.source;
};
```
## Build
```bash
appc ti build -p ios --build-only
```

## Legal

This module is Copyright (c) 2017-Present by Axway Appcelerator, Inc. All Rights Reserved.
Usage of this module is subject to the Terms of Service agreement with Appcelerator, Inc.  
