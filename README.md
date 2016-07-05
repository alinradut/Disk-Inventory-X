# Disk-Inventory-X
Fork of [Disk Inventory X](http://www.derlien.com/) with the correct volume size formatting and rebuilt external frameworks headers.

As the original author states, "Disk Inventory X is a disk usage utility for Mac OS X 10.3 (and later). It shows the sizes of files and folders in a special graphical way called "treemaps". If you've ever wondered where all your disk space has gone, Disk Inventory X will help you to answer this question."

Since DIX 1.0 was written, OSX APIs have continually changed and one of them was the introduction of [new behavior for NSNumberFormatter in OSX 10.4](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSNumberFormatter_Class/#//apple_ref/doc/c_ref/NSNumberFormatterBehavior). This new behavior would cause DIX running on OSX 10.4+ to format the volume sizes incorrectly, for example my 465.6 GB HDD was being displayed as 4,65.6GB:

![](https://raw.githubusercontent.com/clawoo/Disk-Inventory-X/master/dix%20wrong.png)

Setting the NSNumberFormatter behavior to NSNumberFormatterBehavior10_0 results in the correct values:

![](https://raw.githubusercontent.com/clawoo/Disk-Inventory-X/master/dix%20right.png)

The main problem in fixing this was that DIX relied on three main external frameworks: OmniFramworks, CocoaTech and TreeMapView. Except for TreeMapView which is provided by the original author, finding the source code for the other two proved difficult. Even if the source code was available, compatibility problems between early versions of Xcode (2.x) and the latest Xcode (7.2) would make it troublesome to compile.

Therefore, I extracted the prebuilt frameworks from the Disk Inventory X.app bundle and recreated the headers as follows:

## CocoaTech 

This has proved most annoying as I haven't been able to find versions of the Path Finder SDK from the same epoch as DIX and the contemporary SDK is incompatible, in the sense that it's wholly different.

Luckily, there's a tool called [class-dump](http://stevenygard.com/projects/class-dump/) that came to the rescue. Feed it a framework bundle and it will output a header file for each class it finds along with the correct methods and members. Took the generated headers and placed them inside the framework bundle in the Headers folder. I did have to modify them slightly, but overall it was easy.

## OmniFrameworks

OmniGroup has kindly made available their source repo, but it goes back only as far as 2009. Fortunately, it didn't change much, and I was able to extract the header files and integrate them with the prebuilt version of the framework that was distributed with DIX. There's no need to go hunting in all the folders to extract the headers, just go to the target settings > build phases > headers:

![](https://raw.githubusercontent.com/clawoo/Disk-Inventory-X/master/omniframeworks%20headers.png)

## TreeMapView

The Xcode project file is no longer compatible with contemporary versions of Xcode so I had to manually copy the header files, which was ok because they were only a handful.

# Building

Clone the repository and open the project file located in Disk Inventory X 1.0 src/make/src/Disk Inventory X.xcodeproj and then hit CMD+B.

