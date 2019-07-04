# PHFDelegateChain

This `NSProxy` subclass allows you to chain delegate methods easily. Create an instance of `PHFDelegateChain`, tell it which objects it should forward to and set it as the delegate of an object. Whenever a method is called on the chain, it will forward it to the registered objects.

```objectivec
[tableView setDelegate:(id<UITableViewDelegate>)[PHFDelegateChain delegateChainWithObjects:anObject, anotherObject, nil]];
```

## Characteristics of the chain

To be as transparent as possible, `PHFDelegateChain` has the following introspection behaviors:

- `respondsToSelector:` returns `YES` iff at least one of the registered objects responds to the selector.
- `conformsToProtocol:` returns `YES` iff at least one of the registered objects conforms to the protocol.

Further, only `void` methods are passed to multiple objects along the chain. Non-`void` methods return a value and therefore only the first object in the chain that responds to the selector will receive it, thus breaking the chain at the first object able to handle the invocation. This chain breaking behavior can also be applied to `void` methods by setting the `__breaking` property to `YES`.

The `NSMutableArray` that holds the chain objects only references them weakly in order to avoid circular references.

## Usage

Usually a class that implements delegates defines an accompanying protocol and enforces it on the delegate object. In these cases it is necessary to type cast the `PHFDelegateChain` instance. Note that it is your responsibility to implement the required protocol methods inside the chain objects. Otherwise the application will crash when the chain receives a method invocation it can't forward.

```objectivec
@interface EditingDelegate : NSObject <UITableViewDelegate> @end
@interface SelectionDelegate : NSObject <UITableViewDelegate> @end
//
PHFDelegateChain *chain = [PHFDelegateChain delegateChainWithObjects:[EditingDelegate new], [SelectionDelegate new], nil];
[tableView setDelegate:(id<UITableViewDelegate>)chain]; // Protocol typecast needed
```

## Use cases

Delegation chaining can be useful in a number of circumstances, e.g.

- Splitting up the delegation responsibility, such as having one class that handles the editing methods of a table view and another class that handles the selection methods.
- When developing a library that needs to handle certain delegate methods of an object while other delegate methods should be forwarded to a custom delegate. Ever seen code that forwards almost all delegate methods just to be able to hook into one?

```objectivec
- (void)tableView:(UITableView*)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(tableView:willBeginEditingRowAtIndexPath:)])
        [_delegate tableView:tableView willBeginEditingRowAtIndexPath:indexPath];
}
```

## Installation

The preferred method is to use [CocoaPods](https://github.com/CocoaPods/CocoaPods). Simply list `PHFDelegateChain` as a dependency:

```ruby
dependency 'PHFDelegateChain', '~> 1.0'
```

If you can't or don't want to use CocoaPods (you really should, it's great!), simply grab the `PHFDelegateChain.{h,m}` files and put it in your project.

## Development

To hack on this project you will need [CocoaPods](https://github.com/CocoaPods/CocoaPods) installed. If you don't have it yet, get it:

    $ gem install cocoapods

Get all the dependencies and initialize the workspace:

    $ pod install PHFDelegateChain.xcodeproj

Open the workspace:

    $ open PHFDelegateChain.xcworkspace

Make sure to add tests for new features and changes.

## License

`PHFDelegateChain` is released under the MIT license.
