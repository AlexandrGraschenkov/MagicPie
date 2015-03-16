MagicPie
========

Powerful pie layer for creating your own pie view. PieLayer provide great animation with simple usage.

The main advantage of that control that there is no worry about displaying of animation. Animation will display correctly even if you will add new elements during execution of another slice deleting animation. That's amazing! And here is no delegates. I like delegates, but in this case I think they are excess.

<img src="https://github.com/Sk0rpion/MagicPie/blob/master/MagicPie.gif?raw=true" alt="Demo" width="359" height="704" />


<img src="https://github.com/Sk0rpion/MagicPie/blob/master/MagicPie2.gif?raw=true" alt="Demo" width="359" height="704" />

Be creative =)

<img src="https://github.com/Sk0rpion/MagicPie/blob/master/MagicPie3.gif?raw=true" alt="Demo" width="359" height="704" />

<img src="https://github.com/Sk0rpion/MagicPie/blob/master/MagicPie4.gif?raw=true" alt="Demo" width="371" height="665" />


## Installation

Edit your `PodFile` to include the following line:
```
pod 'MagicPie'
```

Then import the main header.
```
#import <MagicPieLayer.h>
```

Have a fun!

## Example Usage

Create pie:
###### Obj-C
```objective-c
PieLayer* pieLayer = [[PieLayer alloc] init];
pieLayer.frame = CGRectMake(0, 0, 200, 200);
[self.view.layer addSublayer:pieLayer];
```
###### Swift
```swift
let pieLayer = PieLayer()
pieLayer.frame = CGRectMake(0, 0, 200, 200)
view.layer.addSublayer(pieLayer)
```

Add slices:
###### Obj-C
```objective-c
[pieLayer addValues:@[[PieElement pieElementWithValue:5.0 color:[UIColor redColor]],
                      [PieElement pieElementWithValue:4.0 color:[UIColor blueColor]],
                      [PieElement pieElementWithValue:7.0 color:[UIColor greenColor]]] animated:YES];
```
###### Swift
```swift
pieLayer.addValues([PieElement(value: 5.0, color: UIColor.redColor()),
                    PieElement(value: 4.0, color: UIColor.blueColor()),
                    PieElement(value: 7.0, color: UIColor.greenColor())], animated: true)
```
                          
Change value with animation:
###### Obj-C
```objective-c
PieElement* pieElem = pieLayer.values[0];
[PieElement animateChanges:^{
	pieElem.val = 13.0;
	pieElem.color = [UIColor yellowColor];
}];
```
###### Swift
```swift
let pieElem = pieLayer.values[0]
PieElement.animateChanges {
	pieElem.val = 13.0
	pieElem.color = UIColor.yellowColor()
}
```

Delete slices:
###### Obj-C
```objective-c
[pieLayer deleteValues:@[pieLayer.values[0], pieLayer.values[1]] animated:YES];
```
###### Swift
```swift
pieLayer.deleteValues([pieLayer.values[0], pieLayer.values[1]], animated: true)
```

## Contact

Alexandr Graschenkov: alexandr.graschenkov91@gmail.com

## License

MagicPie is available under the MIT license.

Copyright © 2013 Alexandr Graschenkov.
