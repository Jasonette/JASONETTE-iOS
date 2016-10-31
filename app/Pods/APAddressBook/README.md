<img src="https://dl.dropboxusercontent.com/u/2334198/APAddressBook-git-teaser.png">

[![Build Status](https://api.travis-ci.org/Alterplay/APAddressBook.svg)](https://travis-ci.org/Alterplay/APAddressBook)

APAddressBook is a wrapper on [AddressBook.framework](https://developer.apple.com/library/ios/documentation/AddressBook/Reference/AddressBook_iPhoneOS_Framework/_index.html) that gives easy access to native address book without pain in a head.

#### Features
* Load contacts from iOS address book asynchronously
* Decide what contact data fields you need to load (for example, only name and phone number)
* Filter contacts to get only necessary records (for example, you need only contacts with email)
* Sort contacts with array of any [NSSortDescriptor](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/NSSortDescriptor_Class/Reference/Reference.html)
* Get photo of contact

#### Objective-c
**Installation**

Add `APAddressBook` pod to [Podfile](http://guides.cocoapods.org/syntax/podfile.html)
```ruby
pod 'APAddressBook'
```

**Load contacts**
```objective-c
APAddressBook *addressBook = [[APAddressBook alloc] init];
// don't forget to show some activity
[addressBook loadContacts:^(NSArray <APContact *> *contacts, NSError *error)
{
    // hide activity
    if (!error)
    {
        // do something with contacts array
    }
    else
    {
        // show error
    }
}];
```

> Callback block will be run on main queue! If you need to run callback block on custom queue use `loadContactsOnQueue:completion:` method

**Select contact fields bit-mask**

Available fields:
* APContactFieldName - *first name*, *last name*, *middle name*, *composite name*
* APContactFieldJob - *company (organization)*, *job title*
* APContactFieldThumbnail - *thumbnail* image
* APContactFieldPhonesOnly - array of *phone numbers* disregarding *phone labels*
* APContactFieldPhonesWithLabels - array *phones* with *original and localized labels*
* APContactFieldEmailsOnly - array of *email addresses* disregarding *email labels*
* APContactFieldEmailsWithLabels - array of *email addresses* with *original and localized labels*
* APContactFieldAddressesWithLabels - array of contact *addresses* with *original and localized labels*
* APContactFieldAddressesOnly - array of contact *addresses* disregarding *addresses labels*
* APContactFieldSocialProfiles - array of contact *profiles in social networks*
* APContactFieldBirthday - date of *birthday*
* APContactFieldWebsites - array of strings with *website URLs*
* APContactFieldNote - string with *notes*
* APContactFieldRelatedPersons - array of *related persons*
* APContactFieldLinkedRecordIDs - array of contact *linked records IDs*
* APContactFieldSource - contact *source ID* and *source name*
* APContactFieldRecordDate - contact record *creation date* and *modification date*
* APContactFieldDefault - contact *name and phones* without *labels*
* APContactFieldAll - all contact fields described above

> Contact `recordID` property is always available

Example of field mask with name and thumbnail:
```objective-c
APAddressBook *addressBook = [[APAddressBook alloc] init];
addressBook.fieldsMask = APContactFieldFirstName | APContactFieldThumbnail;
```

**Filter contacts**

The most common use of this option is to filter contacts without phone number. Example:
```objective-c
addressBook.filterBlock = ^BOOL(APContact *contact)
{
    return contact.phones.count > 0;
};
```

**Sort contacts**

APAddressBook returns unsorted contacts. So, most of users would like to sort contacts by first name and last name.
```objective-c
addressBook.sortDescriptors = @[
    [NSSortDescriptor sortDescriptorWithKey:@"name.firstName" ascending:YES],
    [NSSortDescriptor sortDescriptorWithKey:@"name.lastName" ascending:YES]
];
```

**Load contact by address book record ID**
```objective-c
[addressBook loadContactByRecordID:recordID completion:^(APContact *contact)
{
    self.contact = contact;
}];
```

> `APContact` instance will contain fields that set in `addressBook.fieldsMask`

> Callback block will be run on main queue! If you need to run callback block on custom queue use `loadContactByRecordID:onQueue:completion:` method


**Load contact photo by address book record ID**
```objective-c
[addressBook loadPhotoByRecordID:recordID completion:^(UIImage *image)
{
    self.imageView.image = image;
}];
```
> Callback block will be run on main queue! If you need to run callback block on custom queue use `loadPhotoByRecordID:onQueue:completion:` method


**Observe address book external changes**
```objective-c
// start observing
[addressBook startObserveChangesWithCallback:^
{
    // reload contacts
}];
// stop observing
[addressBook stopObserveChanges];
```

**Request address book access**
```objective-c
[addressBook requestAccess:^(BOOL granted, NSError *error)
{
    // check `granted`
}];
```

**Check address book access**
```objective-c
switch([APAddressBook access])
{
    case APAddressBookAccessUnknown:
        // Application didn't request address book access yet
        break;

    case APAddressBookAccessGranted:
        // Access granted
        break;

    case APAddressBookAccessDenied:
        // Access denied or restricted by privacy settings
        break;
}
```

#### Swift
**Installation**
```ruby
pod 'APAddressBook/Swift'
```
Import `APAddressBook-Bridging.h` to application's objective-c bridging file.
```objective-c
#import <APAddressBook/APAddressBook-Bridging.h>
```

**Example**

See example application in `Example/Swift` directory.
```Swift
self.addressBook.loadContacts(
    { (contacts: [APContact]?, error: NSError?) in
        if let uwrappedContacts = contacts {
            // do something with contacts
        }
        else if let unwrappedError = error {
            // show error
        }
    })
```

#### APContact serialization

Use [APContact-EasyMapping](https://github.com/JeanLebrument/APContact-EasyMapping) by [Jean Lebrument](https://github.com/JeanLebrument)

#### 0.1.x to 0.2.x Migration guide
[Migration Guide](https://github.com/Alterplay/APAddressBook/wiki/0.1.x-to-0.2.x-migration-guide)

#### History

[Releases](https://github.com/Alterplay/APAddressBook/releases)

#### Contributor guide

[Contributor Guide](https://github.com/Alterplay/APAddressBook/wiki/Contributor-Guide)

[![githalytics.com alpha](https://cruel-carlota.pagodabox.com/b3f8691205854e15dcfebe3fc2ed599e "githalytics.com")](http://githalytics.com/Alterplay/APAddressBook)

#### Contacts

If you have improvements or concerns, feel free to post [an issue](https://github.com/Alterplay/APAddressBook/issues) and write details.

[Check out](https://github.com/Alterplay) all Alterplay's GitHub projects.
[Email us](mailto:hello@alterplay.com?subject=From%20GitHub%20APAddressBook) with other ideas and projects.
