//
//  JasonUtilAction.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "JasonUtilAction.h"

@implementation JasonUtilAction
- (void)banner{
    NSString *title = self.options[@"title"];
    NSString *description = self.options[@"description"];
    NSString *type = self.options[@"type"];
    if(!title) title = @"Notice";
    if(!description) description = @"";
    if(!type) type = @"info";
    
    TWMessageBarMessageType type_code;
    if([type isEqualToString:@"error"]){
        type_code = TWMessageBarMessageTypeError;
    } else if([type isEqualToString:@"info"]){
        type_code = TWMessageBarMessageTypeInfo;
    } else {
        type_code = TWMessageBarMessageTypeSuccess;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [[TWMessageBarManager sharedInstance] showMessageWithTitle: title
                                                       description: description
                                                              type: type_code];
    });
    [[Jason client] success];
}




- (void)toast{
    NSString *type = self.options[@"type"];
    NSString *text = self.options[@"text"];
    
    if(!type) type = @"success";
    if(!text) text = @"Updated";
    
    NSString *type_code;
    if([type isEqualToString:@"dark"]){
        type_code = JDStatusBarStyleDark;
    } else if([type isEqualToString:@"default"]){
        type_code = JDStatusBarStyleDefault;
    } else if([type isEqualToString:@"error"]){
        type_code = JDStatusBarStyleError;
    } else if([type isEqualToString:@"matrix"]){
        type_code = JDStatusBarStyleMatrix;
    } else if([type isEqualToString:@"success"]){
        type_code = JDStatusBarStyleSuccess;
    } else if([type isEqualToString:@"warning"]){
        type_code = JDStatusBarStyleWarning;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [JDStatusBarNotification showWithStatus:text dismissAfter:3.0 styleName:type_code];
    });
    [[Jason client] success];
}

- (void)alert{
    [[Jason client] loading:NO];
    NSString *title = self.options[@"title"];
    NSString *description = self.options[@"description"];
    // 1. Instantiate alert
    UIAlertController *alert= [UIAlertController alertControllerWithTitle:title message:description preferredStyle:UIAlertControllerStyleAlert];
    
    // 2. Add Input field
    NSArray *form = self.options[@"form"];
    NSMutableDictionary *form_inputs = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *textFields = [[NSMutableDictionary alloc] init];
    if(form && form.count > 0){
        for(int i = 0 ; i < form.count ; i++){
            NSDictionary *input = form[i];
            if([input[@"type"] isEqualToString:@"hidden"]){
                if(input[@"value"]){
                    form_inputs[input[@"name"]] = input[@"value"];
                }
            } else if([input[@"type"] isEqualToString:@"secure"]){
                [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                    textField.secureTextEntry = YES;
                    textFields[input[@"name"]] = textField;
                    if(input[@"placeholder"]){
                        textField.placeholder = input[@"placeholder"];
                    }
                    if(input[@"value"]){
                        [textField setText:input[@"value"]];
                    }
                }];
            } else {
                // default is text field
                [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                    textField.secureTextEntry = NO;
                    textFields[input[@"name"]] = textField;
                    if(input[@"placeholder"]){
                        textField.placeholder = input[@"placeholder"];
                    }
                    if(input[@"value"]){
                        [textField setText:input[@"value"]];
                    }
                }];
            }
            
        }
    }
    
    
    // 3. Add buttons
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            // Handle callback actions
        if(form && form.count > 0){
            for(NSString *input_name in textFields){
                UITextField *textField = (UITextField *)textFields[input_name];
                [form_inputs setObject:textField.text forKey:input_name];
            }
            [[Jason client] success: form_inputs];
        } else {
            [[Jason client] success];
        }
    }];
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [[Jason client] finish];
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:ok];
    [alert addAction:cancel];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.VC.navigationController presentViewController:alert animated:YES completion:nil];
    });
}
- (void)share{
    NSArray *items = self.options[@"items"];
    NSMutableArray *share_items = [[NSMutableArray alloc] init];
    __block NSInteger counter = items.count;
    if(items && items.count > 0){
        for(int i = 0 ; i < items.count ; i++){
            NSDictionary *item = items[i];
            if(item[@"type"]){
                if([item[@"type"] isEqualToString:@"image"]){
                    NSString *url = item[@"url"];
                    NSString *file_url = item[@"file_url"];
                    if(url){
                        SDWebImageManager *manager = [SDWebImageManager sharedManager];
                        [manager downloadImageWithURL:[NSURL URLWithString:url]
                                              options:0
                                             progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                             }
                                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                                if (image) {
                                                    [share_items addObject:image];
                                                }
                                                counter--;
                                                if(counter == 0) [self openShareWith:share_items];
                                            }];
                    } else if(file_url){
                        [share_items addObject:file_url];
                        counter--;
                        if(counter == 0) [self openShareWith:share_items];
                    } else if(item[@"data"]){
                        NSData *data = [[NSData alloc] initWithBase64EncodedString:item[@"data"] options:0];
                        UIImage *image = [UIImage imageWithData:data];
                        [share_items addObject:image];
                        counter--;
                        if(counter == 0) [self openShareWith:share_items];
                    }
                } else if([item[@"type"] isEqualToString:@"audio"]){
                    NSString *url = item[@"file_url"];
                    if(url){
                        NSURL *file_url = [NSURL fileURLWithPath:url isDirectory:NO];
                        [share_items addObject:file_url];
                        counter--;
                        if(counter == 0) [self openShareWith:share_items];
                    }
                } else if([item[@"type"] isEqualToString:@"video"]){
                    NSString *url = item[@"file_url"];
                    if(url){
                        NSURL *file_url = [NSURL fileURLWithPath:url isDirectory:NO];
                        [share_items addObject:file_url];
                        counter--;
                        if(counter == 0) [self openShareWith:share_items];
                    }
                } else if([item[@"type"] isEqualToString:@"text"]){
                    if(item[@"text"]){
                        [share_items addObject:item[@"text"]];
                    }
                    counter--;
                }
            }
        }
        
        if(counter == 0){
            // this means it can immediately call UIActivityController (No image)
            // Otherwise this should be completed inside the image download complete event
            [self openShareWith:share_items];
        }
    } else {
        [[Jason client] success];
    }
}
- (void)clipboard{
    NSArray *items = self.options[@"items"];
    if(items && items.count > 0){
        UIPasteboard *pasteBoard=[UIPasteboard generalPasteboard];
        NSMutableArray *to_copy = [[NSMutableArray alloc] init];
        for(int i = 0 ; i < items.count ; i++){
            NSDictionary *item = items[i];
            
            if([item[@"type"] isEqualToString:@"gif"]){
                if(item[@"url"]){
                    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:item[@"url"]]];
                    NSDictionary *res = [NSDictionary dictionaryWithObject:data forKey:(NSString *)kUTTypeGIF];
                    [to_copy addObject:res];
                }
            } else if([item[@"type"] isEqualToString:@"text"]){
                if(item[@"text"]){
                    NSDictionary *res = [NSDictionary dictionaryWithObject:item[@"text"] forKey:(NSString *)kUTTypeUTF8PlainText];
                    [to_copy addObject:res];
                }
            } else if([item[@"type"] isEqualToString:@"image"]){
                if(item[@"url"]){
                    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:item[@"url"]]];
                    NSDictionary *res = [NSDictionary dictionaryWithObject:data forKey:(NSString *)kUTTypePNG];
                    [to_copy addObject:res];
                }
            }
        }
        [pasteBoard setItems:to_copy];
    }
    [[Jason client] success];

}
- (void)openShareWith:(NSArray *)items{
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    
    // Exclude all activities except AirDrop.
    NSArray *excludeActivities = @[UIActivityTypePostToFlickr, UIActivityTypePostToVimeo];
    controller.excludedActivityTypes = excludeActivities;
    if(controller.popoverPresentationController){
        controller.popoverPresentationController.sourceView = self.VC.view;
    }
    
    // Present the controller
    [controller setCompletionWithItemsHandler:
      ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
          [[Jason client] success];
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.VC.navigationController presentViewController:controller animated:YES completion:nil];
    });

}
- (void)picker{
    NSString *title = self.options[@"title"];
    NSArray *items = self.options[@"items"];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for(int i = 0 ; i < items.count ; i++){
        NSDictionary *item = items[i];
        UIAlertAction *action = [UIAlertAction actionWithTitle:item[@"text"]
                                                              style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                  if(item[@"href"]){
                                                                      [[Jason client] go:item[@"href"]];
                                                                  } else if(item[@"action"]){
                                                                      [[Jason client] call:item[@"action"]];
                                                                  }
                                                              }];
        [alert addAction:action];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.VC.navigationController presentViewController:alert animated:YES completion:nil]; // 6
    });
    
}
- (void)datepicker{
    RMActionControllerStyle style = RMActionControllerStyleWhite;
    NSString *title = @"Select";
    NSString *description = @"";
    if(self.options){
        if(self.options[@"title"]){
            title = self.options[@"title"];
        }
        if(self.options[@"description"]){
            description = self.options[@"description"];
        }
    }

    RMAction *selectAction = [RMAction actionWithTitle:@"Ok" style:RMActionStyleDone andHandler:^(RMActionController *controller) {
        NSDate *date = ((UIDatePicker *)controller.contentView).date;
        NSString *res = [NSString stringWithFormat:@"%.0f", [date timeIntervalSince1970]];
        [[Jason client] success:@{@"value": res}];
    }];
    
    //Create cancel action
    RMAction *cancelAction = [RMAction actionWithTitle:@"Cancel" style:RMActionStyleCancel andHandler:^(RMActionController *controller) {
        [[Jason client] finish];
    }];
    
    //Create date selection view controller
    RMDateSelectionViewController *dateSelectionController = [RMDateSelectionViewController actionControllerWithStyle:style selectAction:selectAction andCancelAction:cancelAction];
    dateSelectionController.title = title;
    dateSelectionController.message = description;
    
    //Now just present the date selection controller using the standard iOS presentation method
    [self.VC.tabBarController presentViewController:dateSelectionController animated:YES completion:nil];

}
- (void)addressbook{
    APAddressBook *addressbook = [[APAddressBook alloc] init];
    addressbook.fieldsMask = APContactFieldName | APContactFieldEmailsWithLabels | APContactFieldPhonesWithLabels;
    addressbook.filterBlock = ^BOOL(APContact *contact)
    {
        return contact.phones.count > 0;
    };

    addressbook.sortDescriptors = @[
        [NSSortDescriptor sortDescriptorWithKey:@"name.firstName" ascending:YES],
        [NSSortDescriptor sortDescriptorWithKey:@"name.lastName" ascending:YES]
    ];
    switch([APAddressBook access])
    {
        case APAddressBookAccessUnknown:
        {
            // Application didn't request address book access yet
            [addressbook requestAccess:^(BOOL granted, NSError *error)
            {
                if(error){
                    [[Jason client] error];
                } else {
                    if(granted){
                        [self fetchAddressbook: addressbook];
                    } else {
                        [[Jason client] error];
                    }
                }
            }];
            break;
        }
        case APAddressBookAccessGranted:
        {
            // Access granted
            [self fetchAddressbook: addressbook];
            break;
        }
        case APAddressBookAccessDenied:
        {
            // Access denied or restricted by privacy settings
            [[Jason client] error];
            break;
        }
    }

}
- (void)fetchAddressbook: (APAddressBook *)addressbook{
    [[Jason client] loading:YES];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [addressbook loadContacts:^(NSArray <APContact *> *contacts, NSError *error)
        {
            // hide activity
            if (!error)
            {
                // do something with contacts array
                NSMutableArray *result = [NSMutableArray array];
                [contacts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [result addObject:[NSDictionary dictionaryWithObjects:@[[self contactName:obj], [self contactPhones:obj], [self contactEmails:obj]] forKeys:@[@"name", @"phone", @"email"]]];
                }];

                [[Jason client] success: result];
            }
            else
            {
                // show error
                [[Jason client] error];
            }
        }];
    });
    
}
- (NSString *)contactName:(APContact *)contact
{
    if (contact.name.compositeName)
    {
        return contact.name.compositeName;
    }
    else if (contact.name.firstName && contact.name.lastName)
    {
        return [NSString stringWithFormat:@"%@ %@", contact.name.firstName, contact.name.lastName];
    }
    else if (contact.name.firstName || contact.name.lastName)
    {
        return contact.name.firstName ?: contact.name.lastName;
    }
    else
    {
        return @"Untitled";
    }
}
 
- (NSArray *)contactPhones:(APContact *)contact
{
    if (contact.phones.count > 0)
    {
        NSMutableArray *result = [[NSMutableArray alloc] init];
        for (APPhone *phone in contact.phones)
        {
            if(phone.localizedLabel.length == 0){
                [result addObject:@{@"type": @"", @"text": phone.number}];
            } else {
                [result addObject:@{@"type": phone.localizedLabel, @"text": phone.number}];
            }
        }
        return result;
    }
    else
    {
        return @[];
    }
}
 
- (NSArray *)contactEmails:(APContact *)contact
{
    if (contact.emails.count > 1)
    {
        NSMutableArray *result = [[NSMutableArray alloc] init];
        for (APEmail *email in contact.emails)
        {
            [result addObject:email.address];
        }
        return result;
    }
    else
    {
        if(contact.emails.count == 1){
            return @[contact.emails[0].address];
        } else {
            return @[];
        }
    }
}

@end
