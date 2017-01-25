//
//  Jason.m
//  Jasonette
//
//  Copyright © 2016 gliechtenstein. All rights reserved.
//
#import "Jason.h"
#import "JasonAppDelegate.h"
@interface Jason(){
    UINavigationController *navigationController;
    UITabBarController *tabController;
    REMenu *menu_component;
    UIViewController<RussianDollView> *VC;
    NSString *title;
    NSString *desc;
    NSString *icon;
    id module;
    UIBarButtonItem *rightButtonItem;
    PBJVision *vision;
    NSString *ROOT_URL;
    BOOL INITIAL_LOADING;
    BOOL isForeground;
}
@end

@implementation Jason


#pragma mark - Jason Core initializers
+ (Jason*)client {
    static dispatch_once_t predicate = 0;
    static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}
- (id)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onForeground) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        self.searchMode = NO;

        // Add observers for public API
        [[NSNotificationCenter defaultCenter]
                addObserver:self
                   selector:@selector(notifySuccess:)
                       name:@"Jason.success"
                     object:nil];

        [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(notifyError:)
                   name:@"Jason.error"
                 object:nil];

    }
    return self;
}

#pragma mark - Jason Core API Notifications
- (void)notifySuccess:(NSNotification *)notification {
    NSDictionary *args = notification.object;
    NSLog(@"JasonCore: notifySuccess: %@", args);
    [[Jason client] success:args];
}

- (void)notifyError:(NSNotification *)notification {
    NSDictionary *args = notification.object;
    NSLog(@"JasonCore: notifyError: %@", args);
    [[Jason client] error:args];
}

- (void) loadViewByFile: (NSString *)url{
  
    if ([url hasPrefix:@"file://"] && [url hasSuffix:@".json"]) {

        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        NSString *webrootPath = [resourcePath stringByAppendingPathComponent:@""];  
        NSString *loc = @"file:/";

        NSString *jsonFile = [url stringByReplacingOccurrencesOfString:loc withString:webrootPath];
        NSLog(@"LOCALFILES jsonFile is %@", jsonFile);

        NSFileManager *fileManager = [NSFileManager defaultManager];

        if ([fileManager fileExistsAtPath:jsonFile]) { 
            NSError *error = nil;
            NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath:jsonFile];
            [inputStream open];
            VC.original = [NSJSONSerialization JSONObjectWithStream: inputStream options:kNilOptions error:&error];
            [self drawViewFromJason: VC.original];
            [inputStream close];
        } else {
            NSLog(@"JASON FILE NOT FOUND: %@", jsonFile);
            [self call:@{@"type": @"$util.banner", 
                                  @"options": @{
                                       @"title": @"Error",
                                       @"description": [NSString stringWithFormat:@"JASON FILE NOT FOUND: %@", url]
                                   }}];


        }
    }
}

#pragma mark - Jason Core API (USE ONLY THESE METHODS TO ACCESS Jason Core!)

- (void)start: (NSDictionary *) href{
    /**************************************************
     *
     * Public API for initializing Jason
     * (ex) [[Jason client] start] from JasonAppDelegate
     *
     **************************************************/
    JasonAppDelegate *app = (JasonAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDictionary *plist = [self getSettings];
    ROOT_URL = plist[@"url"];
    INITIAL_LOADING = plist[@"loading"];
    
    JasonViewController *vc = [[JasonViewController alloc] init];
    if(href){
        if(href[@"url"]){
            vc.url = href[@"url"];
        }
        if(href[@"options"]){
            vc.options = href[@"options"];
        }
        if(href[@"loading"]){
            vc.loading = href[@"loading"];
        }
    } else {
        vc.url = ROOT_URL;
        vc.loading = INITIAL_LOADING;
    }
    vc.view.backgroundColor = [UIColor whiteColor];
    vc.extendedLayoutIncludesOpaqueBars = YES;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    navigationController.navigationBar.shadowImage = [UIImage new];
    [navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    navigationController.navigationBar.translucent = NO;
    navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
    [JasonHelper setStatusBarBackgroundColor: [UIColor clearColor]];
    
    UITabBarController *tab = [[UITabBarController alloc] init];
    tab.tabBar.backgroundColor = [UIColor whiteColor];
    tab.tabBar.shadowImage = [[UIImage alloc] init];
    tab.viewControllers = @[nav];
    tab.tabBar.hidden = YES;
    
    [tab setDelegate:self];
    
    app.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    app.window.rootViewController = tab;
    
    [app.window makeKeyAndVisible];
}
- (void)call: (NSDictionary *)action{
    /**************************************************
     *
     * Invoke any action from any module
     * (ex) [[Jason client] call: @{@"type": @"$render"}]
     *
     **************************************************/
      [self call: action with: nil];
}
- (void)call: (NSDictionary *)action with: (NSDictionary*)data{
    if(action){
        JasonMemory *memory = [JasonMemory client];
        memory._stack = action;
        if(data && data.count > 0){
            memory._register = data;
        }
        [self exec];
    }
}
- (void)success{
    /**************************************************
     *
     * ONLY Used from modules as a "success" callback when there's no return value.
     * When successful, return from any module by calling:
     *
     *  [[Jason client] success] ==> No return value
     *
     * When it returns with "success", the returned object will be automatically passed to the next action in the action call chain
     *
     **************************************************/
    [self success:@{}];
}
- (void)success: (id)result{
    /**************************************************
     *
     * ONLY Used from Actions as a "success" callback when there's a return value.
     * When successful, return from any module by calling:
     *
     *  [[Jason client] success: result] ==> 'result' can be accessed using the variable '$jason' in the next action
     *
     * When it returns with "success", the returned object will be automatically passed to the next action in the action call chain
     *
     **************************************************/
    
    if(result){
        if([result isKindOfClass:[NSDictionary class]]){
            if(((NSDictionary *)result).count > 0){
                [JasonMemory client]._register = @{@"$jason": result};
            } else {
                [JasonMemory client]._register = result;
            }
        } else {
            [JasonMemory client]._register = @{@"$jason": result};
        }
    } else {
        [JasonMemory client]._register = @{@"$jason": @{}};
    }
    
    [self networkLoading:NO with:nil];
    [self next];
}
- (void)error{
    /**************************************************
     *
     * ONLY Used from modules as a "error" callback.
     *
     *  [[Jason client] error] ==> No return value
     *
     **************************************************/
    [self error:@{}];
}
- (void)error: (id)result{
    /**************************************************
     *
     * ONLY Used from modules as a "error" callback.
     *
     *  [[Jason client] error: result] ==> 'result' can be accessed in the error handling action using the variable '$jason'
     *
     **************************************************/
    
    if(result){
        if([result isKindOfClass:[NSDictionary class]]){
            if(((NSDictionary *)result).count > 0){
                [JasonMemory client]._register = @{@"$jason": result};
            } else {
                [JasonMemory client]._register = result;
            }
        } else {
            [JasonMemory client]._register = @{@"$jason": result};
        }
    } else {
        [JasonMemory client]._register = @{@"$jason": @{}};
    }
    
    // In case oauth was in process, set it back to No
    self.oauth_in_process = NO;
    [self exception];
}
- (void)loading:(BOOL)turnon{
    /************************************************************************************
     *
     * Loading indicator
     * 
     * pass YES to start loading
     * pass NO to end loading
     *
     **************************************************************************************/
    if(turnon){
        [JDStatusBarNotification addStyleNamed:@"SBStyle1"
                                       prepare:^JDStatusBarStyle *(JDStatusBarStyle *style) {
                                           style.barColor = navigationController.navigationBar.backgroundColor;
                                           style.textColor = navigationController.navigationBar.tintColor;
                                           style.animationType = JDStatusBarAnimationTypeFade;
                                           return style;
                                       }];
        [JDStatusBarNotification showWithStatus:@"Loading" styleName:@"SBStyle1"];
        if(navigationController.navigationBar.barStyle == UIStatusBarStyleDefault){
            [JDStatusBarNotification showActivityIndicator:YES indicatorStyle:UIActivityIndicatorViewStyleWhite];
        } else {
            [JDStatusBarNotification showActivityIndicator:YES indicatorStyle:UIActivityIndicatorViewStyleGray];
        }

    } else {
        if([JDStatusBarNotification isVisible]){
            [JDStatusBarNotification dismissAnimated:YES];
        }
    }
}

-(void)networkLoading:(BOOL)turnon with: (NSDictionary *)options;{
    
    if(turnon && (options == nil || (options != nil && options[@"loading"] && [options[@"loading"] boolValue]))){
        MBProgressHUD * hud = [MBProgressHUD showHUDAddedTo:VC.view animated:true];
        hud.animationType = MBProgressHUDAnimationFade;
        
    }
    else if(!turnon){
        [MBProgressHUD hideHUDForView:VC.view animated:true];
    }
}

# pragma mark - Jason public API (Can be accessed by calling {"type": "$(METHOD_NAME)"}
- (void)parse{
    NSDictionary *options = [self options];
    if(options[@"data"] && options[@"template"]){
        id data = options[@"data"];
        NSString *template_name = options[@"template"];
        id template = VC.parser[template_name];
        id result = [JasonHelper parse:data with:template];
        [self success:result];
    } else {
        [self error:@{@"message": @"Need to pass both data and template"}];
    }
}
- (void)href{
    JasonMemory *memory = [JasonMemory client];
    NSDictionary *href = [self options];
    VC.callback = href[@"success"];     // Preserve callback so when the view returns it will continue executing the next action from where it left off.
    memory._stack = @{}; // empty stack before visiting
    memory.executing = NO;
    [self go:href];
}
- (void)search{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"focusSearch" object:nil];
}
- (void)blur{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"blur" object:nil];
}
- (void)home{
    [self unlock];
    [self go:@{@"transition": @"root"}];
}
- (void)close{
    [self ok];
}
- (void)back{
    /********************************************************************************
     *
     * Go back to previous view
     *  if it's a modal, dismiss the modal
     *  if not, pop back
     *
     ********************************************************************************/
     
    if(VC.isModal){
        [navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [navigationController popViewControllerAnimated:YES];
    }
}
- (void)cancel{
    [self unlock];
    [self ok];
}
- (void)ok{
    // When user decides to close on intro without "Open"ing, should respect the decision and
    // remove local_jason
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults valueForKey:@"local_jason"]){
        [defaults removeObjectForKey:@"local_jason"];
        [defaults synchronize];
    }
    // Dismiss Keyboard
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissSearchInput" object:nil];
    [VC.view endEditing:YES];
    
    // Act and close
    JasonMemory *memory = [JasonMemory client];
    if(memory._stack && memory._stack.count > 0){
      memory.need_to_exec = YES;
    } else {
      [self unlock];
    }

    if(menu_component){
        if([menu_component isOpen]){
            [menu_component close];
        }
    }
    [navigationController setToolbarHidden:YES];
    [navigationController dismissViewControllerAnimated:YES completion:nil];
}
- (void)ok: (NSDictionary *)data{
    JasonMemory *memory = [JasonMemory client];
    if(memory._stack && memory._stack.count > 0){
      if(data && data.count > 0) {
        [memory set_register: data];
      }
    }
    [self ok];
}
- (void)set{
    NSDictionary * kv = [self options];
    for(NSString *key in kv){
        VC.form[key] = kv[key];
    }
    [self success];
}
- (void)menu{
    if(menu_component){
        if([menu_component isOpen]){
            [menu_component close];
            return;
        }
    }
    JasonMemory *memory = [JasonMemory client];
    
    NSDictionary *options = memory._stack[@"options"];
    if(!options) return;
    
    NSArray *items = options[@"items"];
    
    
    if(items && items.count > 0){
        NSMutableArray *menu_item_array = [[NSMutableArray alloc] init];
        UIColor *backgroundColor = navigationController.navigationBar.barTintColor;
        UIColor *foregroundColor = navigationController.navigationBar.tintColor;
        for(NSDictionary *item in items){
            NSString *itemtitle = item[@"text"];
            NSString *subtitle = @"";
            NSDictionary *item_action = item[@"action"];
            NSDictionary *item_href = item[@"href"];
            REMenuItem *menuItem = [[REMenuItem alloc] initWithTitle:itemtitle
                                                    subtitle:subtitle
                                                       image:nil
                                            highlightedImage:nil
                                                      action:^(REMenuItem *item) {
                                                            [menu_component close];
                                                            if(item_action){
                                                                [memory set_stack:item_action];
                                                                [self exec];
                                                            } else if (item_href){
                                                                [self go:item_href];
                                                            }
                                                      }];
            
            menuItem.backgroundColor = backgroundColor;
            menuItem.textColor = foregroundColor;
            menuItem.font = [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:14.0];
            menuItem.separatorColor = menuItem.backgroundColor;
            [menu_item_array addObject:menuItem];
        }
        menu_component =[[REMenu alloc] initWithItems:menu_item_array];
        menu_component.backgroundColor = backgroundColor;
        menu_component.borderColor = backgroundColor;
        menu_component.shadowRadius = 0.0;
        menu_component.separatorHeight = 0.0;
        menu_component.itemHeight = 50.0;
        menu_component.animationDuration = 0.1;
        [menu_component showFromNavigationController:navigationController];
    }
    
}
- (void)render{
    NSDictionary *stack = [JasonMemory client]._stack;
    
    /**************************************************
     *
     * PART 1: Prepare data by filling it in with all the variables
     *
     **************************************************/
    if([JasonMemory client]._register && [JasonMemory client]._register.count > 0){
        VC.data = [JasonMemory client]._register;
    }
    NSMutableDictionary *data_stub;
    if(VC.data){
        data_stub = [VC.data mutableCopy];
    } else {
        data_stub = [[NSMutableDictionary alloc] init];
    }
    if(stack[@"options"]){
        if(!stack[@"options"][@"html"]){
            if(stack[@"options"][@"data"]){
                /**************************************************
                 *
                 * You can pass in 'data' as one of the options for $render action, like so:
                 *
                 *    {
                 *        "type": "$render",
                 *        "options": {
                 *           "data": {
                 *               "results": [{
                 *                   "id": "1",
                 *                   "name": "tom"
                 *               }, {
                 *                   "id": "2",
                 *                   "name": "kat"
                 *               }]
                 *            }
                 *        }
                 *   }
                 *
                 * In this case, we override whatever data gets passed in from the register with the data object that's manually passed in.
                 *
                 **************************************************/
                data_stub = [self filloutTemplate:stack[@"options"][@"data"] withData:nil];
            }
        }
    }
    NSDictionary *kv = [self variables];
    for(NSString *key in kv){
        data_stub[key] = kv[key];
    }
    VC.data = data_stub;
    
    /**************************************************
     *
     * PART 2: Get the template
     *
     **************************************************/
    
    // The default template is 'body'
    NSString *template_name = @"body";

    if(stack[@"options"] && stack[@"options"][@"template"]){
        /**************************************************
         *
         * render can have 'template' attribute as an option, like so:
         *
         *    {
         *        "type": "$render",
         *        "options": {
         *           "template": "empty"
         *        }
         *    }
         *
         * In this case we use the specified 'empty' template instead of 'body'
         **************************************************/
        template_name = stack[@"options"][@"template"];
    }
    NSDictionary *body_parser = VC.parser[template_name];
        
        
    /**********************************************************************
     *
     * PART 3: Actually render the prepared data with the selected template
     *
     **********************************************************************/
    if(body_parser){
        
        // if self.data is not empty, render
        NSDictionary *rendered_page;
        if(stack[@"options"] && stack[@"options"][@"type"]){
            if([stack[@"options"][@"type"] isEqualToString:@"html"]){
                rendered_page = [JasonHelper parse: data_stub ofType:@"html" with:body_parser];
            } else if([stack[@"options"][@"type"] isEqualToString:@"xml"]){
                rendered_page = [JasonHelper parse: data_stub ofType:@"xml" with:body_parser];
            } else {
                rendered_page = [JasonHelper parse: data_stub with:body_parser];
            }
        } else {
            rendered_page = [JasonHelper parse: data_stub with:body_parser];
        }
        VC.rendered = rendered_page;
        
        if(rendered_page){
            // Deprecated
            if(rendered_page[@"nav"]) {
                [self setupHeader:rendered_page[@"nav"]];
            } else if(rendered_page[@"header"]) {
                // Use This
                [self setupHeader:rendered_page[@"header"]];
            } else {
                [self setupHeader:nil];
            }
            
            if(rendered_page[@"footer"] && rendered_page[@"footer"][@"tabs"]){
                // Use this
                [self setupTabBar:rendered_page[@"footer"][@"tabs"]];
            } else {
                // Deprecated
                [self setupTabBar:rendered_page[@"tabs"]];
            }
            
            
            if(rendered_page[@"style"] && rendered_page[@"style"][@"background"]){
                if([rendered_page[@"style"][@"background"] isKindOfClass:[NSDictionary class]]){
                    // Advanced background
                    // example:
                    //  "background": {
                    //      "type": "camera",
                    //      "options": {
                    //          ...
                    //      }
                    //  }
                    [self drawAdvancedBackground:rendered_page[@"style"][@"background"]];
                } else {
                    [self drawBackground:rendered_page[@"style"][@"background"]];
                }
            } else {
                [self drawBackground:@"#ffffff"];
            }
        }
        
        if([VC respondsToSelector:@selector(reload:)]) [VC reload:rendered_page];
        
        // Cache the view after drawing
        [self cache_view];
    }
    
    
    [self success];
    
}
- (void)visit{
    JasonMemory *memory = [JasonMemory client];
    NSMutableDictionary *href = [[self options] mutableCopy];
    memory._stack = @{};
    NSString *url = href[@"url"];
    if(url && url.length > 0){
        url = [url stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if([url hasPrefix:@"data:"]){
            url = url;
        }else if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) {
            url = url;
        } else {
            url = [NSString stringWithFormat:@"http://%@", url];
        }
        href[@"url"] = url;
        [self call:@{
             @"type": @"$href",
             @"options": href
         }];
    }
}

- (void)snapshot{
    if(vision){
        vision = [PBJVision sharedInstance];
        vision.cameraMode = PBJCameraModePhoto;
        [vision capturePhoto];
    } else {
        UIImage *image = [JasonHelper takescreenshot];
        NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
        NSString *contentType = @"image/jpeg";
        NSString *dataFormatString = @"data:image/jpeg;base64,%@";
        NSString* dataString = [NSString stringWithFormat:dataFormatString, [imageData base64EncodedStringWithOptions:0]];
        NSURL* dataURI = [NSURL URLWithString:dataString];
        [[Jason client] success:@{@"data": imageData, @"data_uri": dataURI.absoluteString, @"content_type" :contentType}];
    }
}


# pragma mark - View initialization & teardown
- (Jason *)detach:(UIViewController<RussianDollView>*)viewController{
    // Need to clean up before leaving the view
    VC = (UIViewController<RussianDollView>*)viewController;
    
    // Reset Timers
    for(NSString *timer_name in VC.timers){
        NSTimer *timer = VC.timers[timer_name];
        [timer invalidate];
        [VC.timers removeObjectForKey:timer_name];
    }
    
    // Reset Audios
    for(NSString *audio_name in VC.audios){
        FSAudioStream *audio = VC.audios[audio_name];
        [audio stop];
        [VC.audios removeObjectForKey:audio];
    }
    
    // Reset Video
    for(AVPlayer *player in VC.playing){
        [player pause];
    }
    [VC.playing removeAllObjects];
    
    [VC.view endEditing:YES];
    
    return self;
}
- (Jason *)attach:(UIViewController<RussianDollView>*)viewController{
   
    // When oauth is in process, let it do its job and don't interfere.
    if(self.oauth_in_process) return self;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissSearchInput" object:nil];
    
    VC = (UIViewController<RussianDollView>*)viewController;
    navigationController = viewController.navigationController;
    navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
    tabController = navigationController.tabBarController;
    tabController.delegate = self;
    
    VC.url = [VC.url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
  
    // Set the stylesheet
    if(VC.style){
        JasonComponentFactory.stylesheet = [VC.style mutableCopy];
        JasonComponentFactory.stylesheet[@"$default"] = @{@"color": VC.view.tintColor};
    }
    
    
    JasonMemory *memory = [JasonMemory client];
    
    if(memory.executing){
        // if an action is currently executing, don't do anything
    } else if(memory.need_to_exec){
        // Check if there's any action left in the action call chain. If there is, execute it.
        
        // If there's a callback waiting to be executing for the current VC, set it as stack
        if(VC.callback)
        {
            // 1. Replace with VC.callback
            memory._stack = VC.callback;
            
            // 2. Fill it out with return values via options
            memory._stack = [self options];
        }
        
        if(memory._stack && memory._stack.count > 0){
            [self next];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"finishRefreshing" object:nil];
            [self reload];
        }
        memory.need_to_exec = NO;
    }
    
    // If there's nothing to execute, now it's time to display content
    else
    {
        VC.data = nil;
        
        /*********************************************************************************************************
         *
         * VC.rendered: contains the rendered Jason DOM if it's been dynamically rendered.
         *
         * If VC.rendered is not nil, it means it's been already fully rendered.
         *
         ********************************************************************************************************/
        if(VC.rendered){
            
            /*********************************************************************************************************
             *
             * We need to redraw the already rendered final result instead of the pre-rendered markup
             *
             * For example, in: {"head": {"title": "{{$params.name}}", ...}}
             * It will draw "{{$params.name}}" as the title of the nav bar if we don't draw from the already rendered markup.
             *
             ********************************************************************************************************/
            if(VC.rendered[@"nav"]) {
                // Deprecated
                [self setupHeader:VC.rendered[@"nav"]];
            } else if(VC.rendered[@"header"]) {
                [self setupHeader:VC.rendered[@"header"]];
            } else {
                [self setupHeader:nil];
            }
            
            if(VC.rendered[@"footer"] && VC.rendered[@"footer"][@"tabs"]){
                // Use this
                [self setupTabBar:VC.rendered[@"footer"][@"tabs"]];
            } else {
                // Deprecated
                [self setupTabBar:VC.rendered[@"tabs"]];
            }
            [self onShow];
        }
        
        
        /*********************************************************************************************************
         *
         * If VC.rendered is nil, it means the current view has been statically rendered. (no $render calls)
         *
         ********************************************************************************************************/
        else {
            /*********************************************************************************************************
             *
             * If content has been loaded already,
             *  1. redraw navbar
             *  2. re-setup event listener
             *
             ********************************************************************************************************/
            if(VC.contentLoaded){
                // If content already loaded,
                // 1. just setup the navbar so the navbar will have the correct style
                // 2. trigger load events ($show or $load)
                [self setupHeader:VC.nav];
                [self onShow];
            }
            /*********************************************************************************************************
             *
             * If content has not been loaded yet, do a fresh reload
             *
             ********************************************************************************************************/
            else {
                [self reload];
            }
            
        }
    }
    return self;
}
- (void)open{
    // First time visit (with the intro)
    VC.contentLoaded = NO;
    VC.rendered = nil;
    [self success];
}
- (void)flush{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [self success];
}
- (void)kill{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [self reset];
}
- (void)reset{
    // like render, but completely reset all data
    VC.contentLoaded = NO;
    VC.rendered = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [VC viewDidLoad];
        [VC viewWillAppear:NO];
    });
}

# pragma mark - Template related
/****************************************************************************
 *
 * filloutTemplate: withData:
 *
 * 1. Takes any template expression
 * 2. Fills it in with: the value passed in + environment values such as keys, cache, local variable, etc.
 * 3. Retruns the instantiated result
 *
 ****************************************************************************/
- (id)filloutTemplate: (id)template withData:(id)data{
    
    // Step 1. Take the passed in data and merge it with env variables ($get, $cache, $keys, $jason)
    NSMutableDictionary *data_stub = [data mutableCopy];
    NSDictionary *kv = [self variables];
    for(NSString *key in kv){
        data_stub[key] = kv[key];
    }
    
    // Step 2. Fill out the stack with the prepared data_stub (completely filled out from above steps)
    id res = [JasonHelper parse:data_stub with:template];
    
    // Step 3. Return (after typecasting)
    if([res isKindOfClass:[NSArray class]]){
        return (NSArray *)res;
    } else {
        return (NSDictionary *)res;
    }
}
- (NSArray *)getKeys{
    
    /*********************************************************************************************************
    *
    * You can set the key globally on the app by changing "settings.plist" file.
    * Keys from the settings.plist overrides everything else from above.
    *
    ********************************************************************************************************/
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSDictionary *plist = [self getSettings];
    for(NSString *key in plist){
        if(![key isEqualToString:@"url"]){
            NSString *new_key = [NSString stringWithFormat:@"$keys.%@", key];
            dict[new_key] = plist[key];
        }
    }
    
    NSMutableArray *newKeys = [[NSMutableArray alloc] init];
    for(NSString *key in dict){
        [newKeys addObject:@{@"key": key, @"val": dict[key]}];
    }
    return [newKeys copy];
}
-(NSDictionary*)getSettings{
    NSDictionary * infoPlistSettings = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"settings"];
    if(infoPlistSettings != nil){//target's info.plist file contains customized settings
        return infoPlistSettings;
    }else{//settings not found in target's Info.plist - get from file 
        NSURL *file = [[NSBundle mainBundle] URLForResource:@"settings" withExtension:@"plist"];
        NSDictionary *settingsPlistSettings = [NSDictionary dictionaryWithContentsOfURL:file];
        return settingsPlistSettings;
    }
}
- (NSDictionary *)getEnv{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSURL *file = [[NSBundle mainBundle] URLForResource:@"Info" withExtension:@"plist"];
    NSDictionary *info_plist = [NSDictionary dictionaryWithContentsOfURL:file];
    dict[@"url_scheme"] = info_plist[@"CFBundleURLTypes"][0][@"CFBundleURLSchemes"][0];
    return dict;
}
- (NSDictionary *)variables{
    NSMutableDictionary *data_stub = [[NSMutableDictionary alloc] init];    
    if(VC.data){
        for(NSString *key in VC.data){
            if(![key isEqualToString:@"$jason"]){
                data_stub[key] = VC.data[key];
            }
        }
    }

    if(VC.form){
        data_stub[@"$get"] = VC.form;
    }
    if(VC.options){
        data_stub[@"$params"] = VC.options;
    }
    NSArray *keys = [self getKeys];
    if(keys && keys.count > 0){
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for(NSDictionary *kv in keys){
            NSString *key = kv[@"key"];
            NSArray *split = [key componentsSeparatedByString:@"."];
            if([split count] == 2){
                NSString *key_name = [split lastObject];
                NSString *val = kv[@"val"];
                dict[key_name] = val;
            }
        }
        if([dict count] > 0){
            data_stub[@"$keys"] = dict;
        } else {
            data_stub[@"$keys"] = @{};
        }
    }
    
    NSDictionary *env = [self getEnv];
    data_stub[@"$env"] = env;
    
    if(VC.current_cache){
        if(VC.current_cache.count > 0){
            data_stub[@"$cache"] = VC.current_cache;
        } else {
            data_stub[@"$cache"] = @{};
        }
    } else {
        // Fetch the cache from NSUserDefaults only the first time.
        // After this, VC.current_cache will update only when a $set action is called.
        NSString *normalized_url = [VC.url lowercaseString];
        VC.current_cache = [[NSUserDefaults standardUserDefaults] objectForKey:normalized_url];
        if(VC.current_cache && VC.current_cache.count > 0){
            data_stub[@"$cache"] = VC.current_cache;
        } else {
            data_stub[@"$cache"] = @{};
        }
    }
    return data_stub;
}

# pragma mark - View rendering (high level)
- (void)reload{
    VC.data = nil;
    if(VC.url){
       [self networkLoading:VC.loading with:nil];
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        [manager.operationQueue cancelAllOperations];
        NSDictionary *session = [JasonHelper sessionForUrl:VC.url];
        
        // Set Header if specified  "header"
        NSDictionary *headers = self.options[@"header"];
        // legacy code : headers is deprecated
        if(!headers){
            headers = self.options[@"headers"];
        }
        
        if(headers && headers.count > 0){
            for(NSString *key in headers){
                [manager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
            }
        }
        if(session && session.count > 0 && session[@"header"]){
            for(NSString *key in session[@"header"]){
                [manager.requestSerializer setValue:session[@"header"][key] forHTTPHeaderField:key];
            }
        }
        
        
        NSMutableDictionary *parameters;
        if(VC.options[@"data"]){
            parameters = [VC.options[@"data"] mutableCopy];
        } else {
            if(session && session.count > 0 && session[@"body"]){
                parameters = [@{} mutableCopy];
                for(NSString *key in session[@"body"]){
                    parameters[key] = session[@"body"][key];
                }
            } else {
                parameters = nil;
            }
        }
        
        if(VC.fresh){
            [manager.requestSerializer setCachePolicy: NSURLRequestReloadIgnoringLocalCacheData];
            if(!parameters){
                parameters = [@{} mutableCopy];
            }
            int timestamp = [[NSDate date] timeIntervalSince1970];

            parameters[@"timestamp"] = [NSString stringWithFormat:@"%d", timestamp];
        }
        
        VC.contentLoaded=NO;
        
        /**************************************************
         * Experimental : Offline handling
         * => Only load from cache initially if head contains "offline":"true"
         ***************************************************/
        NSString *normalized_url = [self normalized_url];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:normalized_url];
        NSData *data = [NSData dataWithContentsOfFile:path];
        if(data && data.length > 0){
            NSDictionary *responseObject = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            if(responseObject && responseObject[@"$jason"] && responseObject[@"$jason"][@"head"] && responseObject[@"$jason"][@"head"][@"offline"]){
                [self drawViewFromJason: responseObject];
            }
        }
        
        /**************************************************
         * Handling data uri
         ***************************************************/
        if([VC.url hasPrefix:@"data:application/json"]){
            // if data uri, parse it into NSData
            NSURL *url = [NSURL URLWithString:VC.url];
            NSData *jsonData = [NSData dataWithContentsOfURL:url];
            NSError* error;
            VC.original = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
            [self drawViewFromJason: VC.original];
        } else if([VC.url hasPrefix:@"file://"]) {
			[self loadViewByFile: VC.url];
        }
        
        /**************************************************
         * Normally urls are not in data-uri.
         ***************************************************/
        else {
            
            AFJSONResponseSerializer *jsonResponseSerializer = [AFJSONResponseSerializer serializer];
            NSMutableSet *jsonAcceptableContentTypes = [NSMutableSet setWithSet:jsonResponseSerializer.acceptableContentTypes];
            
            // Assumes that content type is json, even the text/plain ones (Some hosting sites respond with data_type of text/plain even when it's actually a json, so we accept even text/plain as json by default)
            [jsonAcceptableContentTypes addObject:@"text/plain"];
            jsonResponseSerializer.acceptableContentTypes = jsonAcceptableContentTypes;
            
            manager.responseSerializer = jsonResponseSerializer;
            
            [manager GET:VC.url parameters:parameters
             progress:^(NSProgress * _Nonnull downloadProgress) { }
             success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // Ignore if the url is different
                 if(![JasonHelper isURL:task.originalRequest.URL equivalentTo:VC.url]) return;
                 VC.original = responseObject;
                [self drawViewFromJason: responseObject];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [self call:@{@"type": @"$util.toast", @"options": @{@"text": @"offline mode"}, @"success": @{@"type": @"$unlock"}}];
            }];
        }
    }
}
- (void)drawViewFromJason: (NSDictionary *)jason{
    
    // Step 0. In case there are passed parameters, we need to fill them in first.
    if([VC respondsToSelector:@selector(options)]){
        if([[VC valueForKey:@"options"] count] > 0){
            NSDictionary *options = @{@"$params": [VC valueForKey:@"options"]};
            NSDictionary *newres = [JasonHelper parse:options with:jason];
            if(newres && newres.count > 0){
                jason = newres;
            }
        }
    }

    NSDictionary *head = jason[@"$jason"][@"head"];
    if(!head)return;
    
    NSDictionary *dom = jason[@"$jason"];
    
    /****************************************************************************
     *
     * Actual drawing starts here
     *
     ****************************************************************************/
    if(dom){
        /****************************************************************************
         *
         * 1. Setup Head
         *
         ****************************************************************************/
        NSDictionary *head = dom[@"head"];
        if(head){
            [self setupHead: head];
            
            /****************************************************************************
             *
             * VC.parser = Template
             *
             ****************************************************************************/
            if(head[@"templates"]){
                VC.parser = head[@"templates"];
            } else {
                VC.parser = nil;
            }
            
            // 3. Set up event
            [self onLoad];
        }
        
        /****************************************************************************
         *
         * 2. Setup Body
         *
         ****************************************************************************/
        NSDictionary *body = dom[@"body"];
        NSDictionary *rendered_page = nil;
        if(body){
            if(body[@"nav"]) {
                // Deprecated
                [self setupHeader:body[@"nav"]];
            } else if(body[@"header"]) {
                // Use this
                [self setupHeader:body[@"header"]];
            } else {
                [self setupHeader:nil];
            }
            
            if(body[@"footer"] && body[@"footer"][@"tabs"]){
                // Use this
                [self setupTabBar:body[@"footer"][@"tabs"]];
            } else {
                // Deprecated
                [self setupTabBar:body[@"tabs"]];
            }
            
            // By default, "body" is the markup that will be rendered
            rendered_page = dom[@"body"];
        } else {
            [self setupHeader:nil];
            [self setupTabBar:nil];
        }
        
        
        /****************************************************************************
         *
         * If VC.parser exists, it means this view needs to be dynamically rendered
         * Therefore we override the rendered_page with a dynamically generated view
         *
         ****************************************************************************/
        if(VC.parser && VC.parser.count > 0){
            NSDictionary *body_parser = VC.parser[@"body"];
            if(body_parser){
                // Pre-render navbar and tabbar first before rendering the VC
                if(body_parser[@"nav"]) {
                    // Deprecated
                    [self setupHeader:body_parser[@"nav"]];
                } else if(body_parser[@"header"]) {
                    // Use thi
                    [self setupHeader:body_parser[@"header"]];
                } else {
                    [self setupHeader: nil];
                }
                if(body_parser[@"footer"] && body_parser[@"footer"][@"tabs"]){
                    // Use this
                    [self setupTabBar:body_parser[@"footer"][@"tabs"]];
                } else {
                    // Deprecated
                    [self setupTabBar:body_parser[@"tabs"]];
                }
                
                // parse the data with the template to dynamically build the view
                if(VC.data && VC.data.count > 0) rendered_page = [JasonHelper parse: VC.data with:body_parser];
            }
        }
        
        if(rendered_page){
            VC.rendered = rendered_page;
            // In case it's a different view, we need to reset
            
            if(rendered_page[@"style"] && rendered_page[@"style"][@"background"]){
                if([rendered_page[@"style"][@"background"] isKindOfClass:[NSDictionary class]]){
                    // Advanced background
                    // example:
                    //  "background": {
                    //      "type": "camera",
                    //      "options": {
                    //          ...
                    //      }
                    //  }
                    [self drawAdvancedBackground:rendered_page[@"style"][@"background"]];
                } else {
                    [self drawBackground:rendered_page[@"style"][@"background"]];
                }
            } else {
                [self drawBackground:@"#ffffff"];
            }
            
            if([VC respondsToSelector:@selector(reload:)]) [VC reload:rendered_page];
            
            // Cache the view after drawing
            [self cache_view];
        }
        
    }
    [self loading:NO];
    [self networkLoading:NO with:nil];
}
- (void)drawAdvancedBackground:(NSDictionary*)bg{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *type = bg[@"type"];
        if(type && [type isEqualToString:@"camera"]){
            if(VC.background){
                [VC.background removeFromSuperview];
                VC.background = nil;
            }
            
            NSDictionary *options = bg[@"options"];
            
            
            AVCaptureVideoPreviewLayer *_previewLayer;
            VC.background = [[UIImageView alloc] initWithFrame: [UIScreen mainScreen].bounds];
            _previewLayer = [[PBJVision sharedInstance] previewLayer];
            _previewLayer.frame = VC.background.bounds;
            _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            
            [VC.background.layer addSublayer:_previewLayer];
            
            vision = [PBJVision sharedInstance];
            vision.delegate = self;
            if(options[@"mode"] && [options[@"mode"] isEqualToString:@"video"]){
                vision.cameraMode = PBJCameraModeVideo;
            } else {
                vision.cameraMode = PBJCameraModePhoto;
            }
            vision.cameraOrientation = PBJCameraOrientationPortrait;
            vision.focusMode = PBJFocusModeContinuousAutoFocus;
            if(options[@"device"] && [options[@"device"] isEqualToString:@"back"]){
                vision.cameraDevice = PBJCameraDeviceBack;
            } else {
                vision.cameraDevice = PBJCameraDeviceFront;
            }
            
            [vision startPreview];
            
            [VC.view addSubview:VC.background];
            [VC.view sendSubviewToBack:VC.background];
        }
    });
}
- (void)drawBackground:(NSString *)bg{
    dispatch_async(dispatch_get_main_queue(), ^{

        if([bg isEqualToString:@"camera"]){
            if(VC.background){
                [VC.background removeFromSuperview];
                VC.background = nil;
            }
            
            AVCaptureVideoPreviewLayer *_previewLayer;
            VC.background = [[UIImageView alloc] initWithFrame: [UIScreen mainScreen].bounds];
            _previewLayer = [[PBJVision sharedInstance] previewLayer];
            _previewLayer.frame = VC.background.bounds;
            _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            
            [VC.background.layer addSublayer:_previewLayer];
            
            vision = [PBJVision sharedInstance];
            vision.delegate = self;
            vision.cameraMode = PBJCameraModePhoto;
            vision.cameraOrientation = PBJCameraOrientationPortrait;
            vision.focusMode = PBJFocusModeContinuousAutoFocus;
            vision.cameraDevice = PBJCameraDeviceFront;
            
            [vision startPreview];
            
            [VC.view addSubview:VC.background];
            [VC.view sendSubviewToBack:VC.background];
            
        }else if([bg hasPrefix:@"http"] || [bg hasPrefix:@"data:"]){
            vision = nil;
            if(VC.background){
                [VC.background removeFromSuperview];
                VC.background = nil;
            }
            if(vision) [vision stopPreview];
            VC.background = [[UIImageView alloc] initWithFrame: [UIScreen mainScreen].bounds];
            VC.background.contentMode = UIViewContentModeScaleAspectFill;
            [VC.view addSubview:VC.background];
            [VC.view sendSubviewToBack:VC.background];
            
            UIImage *placeholder_image = [UIImage imageNamed:@"placeholderr"];
            [((UIImageView *)VC.background) sd_setImageWithURL:[NSURL URLWithString:bg] placeholderImage:placeholder_image completed:^(UIImage *i, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            }];
        } else {
            vision = nil;
            if(VC.background){
                [VC.background removeFromSuperview];
                VC.background = nil;
            }
            VC.view.backgroundColor = [JasonHelper colorwithHexString:bg alpha:1.0];
        }
    });

}

- (void)setupHead: (NSDictionary *)head{
    if(head){
        // 1. Event handler
        NSDictionary *event_handlers = head[@"actions"];
        [VC setValue:event_handlers forKey:@"events"];
        
        // 2. data
        VC.data = nil;
        NSDictionary *data = head[@"data"];
        if(data){
            VC.data = data;
        }
        NSDictionary *style = head[@"styles"];
        [VC setValue:style forKey:@"style"];
    }
}

# pragma mark - View rendering (nav)
- (void)setupHeader: (NSDictionary *)nav{
    
    UIColor *background = [JasonHelper colorwithHexString:@"#ffffff" alpha:1.0];
    UIColor *color = [JasonHelper colorwithHexString:@"#000000" alpha:1.0];
    
    // Deprecated (using 'nav' instead of 'header')
    NSArray *items = nav[@"items"];
    if(items){
        NSMutableDictionary *dict = [nav mutableCopy];
        [dict removeObjectForKey:@"items"];
        for(NSDictionary *item in items){
            dict[item[@"type"]] = item;
        }
        nav = dict;
    }
    ////////////////////////////////////////////////////////////////
    
    if(!nav) {
        if(VC.isModal || [tabController presentingViewController]){ // if the current tab bar was modally presented
            // if it's a modal, need to add X button to close
            nav = @{@"left": @{}};
        } else {
            
            navigationController.navigationBar.shadowImage = [UIImage new];
            [navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
            navigationController.navigationBar.translucent = NO;
            [JasonHelper setStatusBarBackgroundColor: [UIColor clearColor]];
            
            navigationController.navigationBar.backgroundColor = background;
            navigationController.navigationBar.barTintColor = background;
            navigationController.navigationBar.tintColor = color;
            navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : color, NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:18.0]};
            return;
        }
    }
    
    navigationController.navigationBar.barStyle = UIStatusBarStyleLightContent;
    navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : color, NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:18.0]};
    [navigationController setNavigationBarHidden:NO];
    if(nav[@"style"]){
        NSDictionary *headStyle = nav[@"style"];
        if(headStyle){
            if(headStyle[@"background"]){
                NSString *bg = headStyle[@"background"];
                background = [JasonHelper colorwithHexString:bg alpha:1.0];
            }
            if(headStyle[@"color"]){
                color = [JasonHelper colorwithHexString:headStyle[@"color"] alpha:1.0];
            }
            
            if(headStyle[@"theme"]){
                navigationController.navigationBar.barStyle = UIStatusBarStyleDefault;
            } else {
                navigationController.navigationBar.barStyle = UIStatusBarStyleLightContent;
            }
            
            if(headStyle[@"shy"]){
                navigationController.hidesBarsOnSwipe = YES;
            } else {
                navigationController.hidesBarsOnSwipe = NO;
            }
            
            
            if(headStyle[@"hide"] && [headStyle[@"hide"] boolValue]){
                dispatch_async(dispatch_get_main_queue(), ^{
                     [navigationController setNavigationBarHidden:YES];
                });
               
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [navigationController setNavigationBarHidden:NO];
                });
                
            }
            
            NSString *font_name = @"HelveticaNeue-CondensedBold";
            NSString *font_size = @"18";
            if(headStyle[@"font"]){
                font_name = headStyle[@"font"];
            }
            if(headStyle[@"size"]){
                font_size = headStyle[@"size"];
            }
            navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : color, NSFontAttributeName: [UIFont fontWithName:font_name size:[font_size integerValue]]};
        }
    }


    NSDictionary *left_menu = nav[@"left"];
    NSDictionary *right_menu;
    
    NSArray *navComponents = nav[@"items"];
    if(navComponents){
        for(NSDictionary *component in navComponents){
            NSString *type = component[@"type"];
            if(type){
                if([type isEqualToString:@"menu"]){
                    right_menu = component;
                    break;
                }
            }
        }
    }
    right_menu = nav[@"menu"];
    
                
    BBBadgeBarButtonItem *leftBarButton;
    if(!left_menu || [left_menu count] == 0){
        // if the current view is in a modal AND is the rootviewcontroller of the navigationcontroller,
        // Add the X button. Otherwise, ignore this.
        if([tabController presentingViewController]){ // if the current tab bar was modally presented
            if([navigationController.viewControllers.firstObject isEqual:VC]){
                leftBarButton = [[BBBadgeBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(cancel)];
                [leftBarButton setTintColor:color];
            }
        }
    } else {
        if(left_menu[@"text"]){
            UIButton *button = [[UIButton alloc] init];
            [button setTitle:left_menu[@"text"] forState:UIControlStateNormal];
            [button setTitle:left_menu[@"text"] forState:UIControlStateFocused];
            NSDictionary *style = left_menu[@"style"];
            if(style && style[@"color"]){
                UIColor *c = [JasonHelper colorwithHexString:style[@"color"] alpha:1.0];
                [button setTitleColor:c forState:UIControlStateNormal];
            } else {
                [button setTitleColor:color forState:UIControlStateNormal];
            }
            CGFloat size = 14.0;
            NSString *font = @"HelveticaNeue";
            if(style[@"size"]){
                size = [style[@"size"] floatValue];
            }
            if(style[@"font"]){
                font = style[@"font"];
            }
            button.titleLabel.font = [UIFont fontWithName: font size:size];
            [button sizeToFit];
            [button addTarget:self action:@selector(leftMenu) forControlEvents:UIControlEventTouchUpInside];
            leftBarButton = [[BBBadgeBarButtonItem alloc] initWithCustomUIButton:button];
        } else {
            UIButton *btn =  [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(0,0,20,20);
            if(left_menu[@"image"]){
                NSString *image_src = left_menu[@"image"];
                SDWebImageManager *manager = [SDWebImageManager sharedManager];
                [manager downloadImageWithURL:[NSURL URLWithString:image_src]
                                      options:0
                                     progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                     }
                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                        if (image) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                NSDictionary *style = left_menu[@"style"];
                                                if(style[@"color"]){
                                                    UIColor *newColor = [JasonHelper colorwithHexString:style[@"color"] alpha:1.0];
                                                    UIImage *newImage = [JasonHelper colorize:image into:newColor];
                                                    [btn setBackgroundImage:newImage forState:UIControlStateNormal];
                                                } else {
                                                    [btn setBackgroundImage:image forState:UIControlStateNormal];
                                                }
                                            });
                                        }
                                    }];
            } else {
                [btn setBackgroundImage:[UIImage imageNamed:@"more"] forState:UIControlStateNormal];
            }
            [btn addTarget:self action:@selector(leftMenu) forControlEvents:UIControlEventTouchUpInside];
            leftBarButton = [[BBBadgeBarButtonItem alloc] initWithCustomUIButton:btn];
        }
        [self setupMenuBadge:leftBarButton forData:left_menu];
    }

    BBBadgeBarButtonItem *rightBarButton;
    if(!right_menu || [right_menu count] == 0){
        rightBarButton = nil;
    } else {
        if(right_menu[@"text"]){
            UIButton *button = [[UIButton alloc] init];
            [button setTitle:right_menu[@"text"] forState:UIControlStateNormal];
            [button setTitle:right_menu[@"text"] forState:UIControlStateFocused];
            NSDictionary *style = right_menu[@"style"];
            if(style && style[@"color"]){
                UIColor *c = [JasonHelper colorwithHexString:style[@"color"] alpha:1.0];
                [button setTitleColor:c forState:UIControlStateNormal];
            } else {
                [button setTitleColor:color forState:UIControlStateNormal];
            }
            CGFloat size = 14.0;
            NSString *font = @"HelveticaNeue";
            if(style[@"size"]){
                size = [style[@"size"] floatValue];
            }
            if(style[@"font"]){
                font = style[@"font"];
            }
            button.titleLabel.font = [UIFont fontWithName: font size:size];
            [button sizeToFit];
            [button addTarget:self action:@selector(rightMenu) forControlEvents:UIControlEventTouchUpInside];
            rightBarButton = [[BBBadgeBarButtonItem alloc] initWithCustomUIButton:button];
        } else {
            UIButton *btn =  [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(0,0,25,25);
            if(right_menu[@"image"]){
                NSString *image_src = right_menu[@"image"];
                SDWebImageManager *manager = [SDWebImageManager sharedManager];
                [manager downloadImageWithURL:[NSURL URLWithString:image_src]
                                      options:0
                                     progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                     }
                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                        if (image) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                NSDictionary *style = right_menu[@"style"];
                                                if(style[@"color"]){
                                                    UIColor *newColor = [JasonHelper colorwithHexString:style[@"color"] alpha:1.0];
                                                    UIImage *newImage = [JasonHelper colorize:image into:newColor];
                                                    [btn setBackgroundImage:newImage forState:UIControlStateNormal];
                                                } else {
                                                    [btn setBackgroundImage:image forState:UIControlStateNormal];
                                                }
                                            });
                                        }
                                    }];
            } else {
                [btn setBackgroundImage:[UIImage imageNamed:@"more"] forState:UIControlStateNormal];
            }
            [btn addTarget:self action:@selector(rightMenu) forControlEvents:UIControlEventTouchUpInside];
            rightBarButton = [[BBBadgeBarButtonItem alloc] initWithCustomUIButton:btn];
        }
        [self setupMenuBadge:rightBarButton forData:right_menu];
    }
    
    if(!VC.menu){
        VC.menu = [[NSMutableDictionary alloc] init];
    }
    [VC.menu setValue:left_menu forKey:@"left"];
    [VC.menu setValue:right_menu forKey:@"right"];
    
    VC.navigationItem.rightBarButtonItem = rightBarButton;
    VC.navigationItem.leftBarButtonItem = leftBarButton;
    
    if(nav[@"title"]){

        if(![[nav[@"title"] description] containsString:@"{{"] && ![[nav[@"title"] description] containsString:@"}}"]){
            if([nav[@"title"] isKindOfClass:[NSDictionary class]]){
                // Advanced title
                NSDictionary *titleDict = nav[@"title"];
                if(titleDict[@"type"]){
                    if([titleDict[@"type"] isEqualToString:@"image"]){
                        NSString *url = titleDict[@"url"];
                        NSDictionary *style = titleDict[@"style"];
                        if(url){
                            SDWebImageManager *manager = [SDWebImageManager sharedManager];
                            [manager downloadImageWithURL:[NSURL URLWithString:url]
                                                  options:0
                                                 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                 }
                                                completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                                    if (image) {
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            CGFloat width = 0;
                                                            CGFloat height = 0;
                                                            if(style && style[@"width"]){
                                                                width = [((NSString *)style[@"width"]) floatValue];
                                                            }
                                                            if(style && style[@"height"]){
                                                                height = [((NSString *)style[@"height"]) floatValue];
                                                            }
                                                            
                                                            
                                                            if(width == 0){
                                                                width = image.size.width;
                                                            }
                                                            if(height == 0){
                                                                height = image.size.height;
                                                            }
                                                            CGRect frame = CGRectMake(0, 0, width, height);
                                                            
                                                            UIView *logoView =[[UIView alloc] initWithFrame:frame];
                                                            UIImageView *logoImageView = [[UIImageView alloc] initWithImage:image];
                                                            logoImageView.frame = frame;
                                                            
                                                            [logoView addSubview:logoImageView];
                                                            VC.navigationItem.titleView = logoView;
                                                            
                                                        });
                                                    }
                                                }];
                        }
                        
                    } else if([titleDict[@"type"] isEqualToString:@"label"]) {
                        VC.navigationItem.titleView = nil;
                        VC.navigationItem.title = titleDict[@"text"];
                    }
                }
            } else if([nav[@"title"] isKindOfClass:[NSString class]]){
                // Basic title (simple text)
                VC.navigationItem.titleView = nil;
                VC.navigationItem.title = nav[@"title"];
            } else {
                VC.navigationItem.titleView = nil;
            }
            
        } else {
            VC.navigationItem.titleView = nil;
        }

    } else {
        VC.navigationItem.titleView = nil;
    }
    
    navigationController.navigationBar.shadowImage = [UIImage new];
    [navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    CGFloat red, green, blue, alpha;
    [background getRed: &red green: &green blue: &blue alpha: &alpha];
    
    if(alpha < 1.0){
        navigationController.navigationBar.translucent = YES;
        [JasonHelper setStatusBarBackgroundColor: background];
    } else {
        navigationController.navigationBar.translucent = NO;
        [JasonHelper setStatusBarBackgroundColor: [UIColor clearColor]];
    }

    navigationController.navigationBar.backgroundColor = background;
    navigationController.navigationBar.barTintColor = background;
    navigationController.navigationBar.tintColor = color;
    
    navigationController.navigationBarHidden = YES;
    navigationController.navigationBarHidden = NO;

}
- (void)setupMenuBadge: (BBBadgeBarButtonItem *)barButton forData: (NSDictionary *)badge_menu{
    if(badge_menu[@"badge"]){
        NSDictionary *badge = badge_menu[@"badge"];
        NSDictionary *style = badge[@"style"];
        if(style){
            if(style[@"background"]){
                barButton.badgeBGColor = [JasonHelper colorwithHexString:style[@"background"] alpha:1.0];
            }
            if(style[@"color"]){
                barButton.badgeTextColor = [JasonHelper colorwithHexString:style[@"color"] alpha:1.0];
            }
            if(style[@"top"]){
                barButton.badgeOriginY = [style[@"top"] floatValue];
            }
            if(style[@"left"]){
                barButton.badgeOriginX = [style[@"left"] floatValue];
            }
        }
        if(badge[@"text"]){
            barButton.badgeValue = badge[@"text"];
        } else {
            barButton.badgeValue = @" ";
        }
    } else {
        barButton.badgeValue = @"";
    }
}
- (void)leftMenu{
    NSDictionary *action = [[VC.menu valueForKey:@"left"] valueForKey:@"action"];
    NSDictionary *href = [[VC.menu valueForKey:@"left"] valueForKey:@"href"];
    JasonMemory *memory = [JasonMemory client];
    if(action){
        [memory set_stack:action];
        [self exec];
    } else if(href){
        [self go:href];
    }
}
- (void)rightMenu{
    NSDictionary *action = [[VC.menu valueForKey:@"right"] valueForKey:@"action"];
    NSDictionary *href = [[VC.menu valueForKey:@"right"] valueForKey:@"href"];
    
    // Set state as the return value
    // Will be processed in the caller viewcontroller's reload
    JasonMemory *memory = [JasonMemory client];
    if(![VC url]){
        // If it's a default VC without URL, call callback
        if([VC respondsToSelector:@selector(right:)]) [VC right:action];
    } else {
        if(action){
            if([VC respondsToSelector:@selector(right:)]){
                [VC right: action];
            } else {
                [memory set_stack:action];
                [self exec];
            }
        } else if(href){
            [self go:href];
        }
    }
}



# pragma mark - View rendering (tab)
- (void)setupTabBar: (NSDictionary *)t{
    
    if(!t){
        tabController.tabBar.hidden = YES;
        return;
    } else {
        tabController.tabBar.hidden = NO;
    }
   
    NSArray *tabs = t[@"items"];
    NSDictionary *style = t[@"style"];
    if(style){
        if(style[@"color"]){
            UIColor *c = [JasonHelper colorwithHexString:style[@"color"] alpha:1.0];
            [tabController.tabBar setTintColor:c];
            [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : c }
                                                     forState:UIControlStateSelected];
            
        }
        if(style[@"color:disabled"]){
            UIColor *c = [JasonHelper colorwithHexString:style[@"color:disabled"] alpha:1.0];
            [[UIView appearanceWhenContainedInInstancesOfClasses:@[[UITabBar class]]] setTintColor:c];
            [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : c }
                                                     forState:UIControlStateNormal];
            
        }
        
        if(style[@"background"]){
            [tabController.tabBar setClipsToBounds:YES];
            tabController.tabBar.shadowImage = [[UIImage alloc] init];
            tabController.tabBar.translucent = NO;
            tabController.tabBar.backgroundColor =[JasonHelper colorwithHexString:style[@"background"] alpha:1.0];
            [tabController.tabBar setBarTintColor:[JasonHelper colorwithHexString:style[@"background"] alpha:1.0]];

        }
        [[UITabBar appearance] setTranslucent:NO];
        [[UITabBar appearance] setBarStyle:UIBarStyleBlack];
    }
    if(tabs && tabs.count > 1){
        NSUInteger maxTabCount = tabs.count;
        if(maxTabCount > 5) maxTabCount = 5;
        BOOL firstTime;
        BOOL tabFound = NO; // at least one tab item with the same url as the current VC should exist.
        NSMutableArray *tabs_array;
        // if not yet initialized, tabController.tabs.count will be 1, since this is the only view
        // that was initialized with
        // In this case, initialize all tabs
        // Start from index 1 because the first one should already be instantiated via modal href
        if(tabController.viewControllers.count != maxTabCount){
            firstTime = YES;
            tabs_array = [[NSMutableArray alloc] init];
        } else {
            firstTime = NO;
        }
        NSUInteger indexOfTab = [tabController.viewControllers indexOfObject:navigationController];
        
        for(int i = 0 ; i < maxTabCount ; i++){
            NSDictionary *tab = tabs[i];
            NSString *url;
            NSDictionary *options = @{};
            if(tab[@"href"]){
                url = tab[@"href"][@"url"];
                options = tab[@"href"][@"options"];
            } else {
                url = tab[@"url"];
            }
            
            if(firstTime){
                if([VC.url isEqualToString:url] && i==indexOfTab){
                    tabFound = YES;
                    // if the tab URL is same as the currently visible VC's url
                    [tabs_array addObject:navigationController];
                } else {
                    JasonViewController *vc = [[JasonViewController alloc] init];
                    vc.url = url;
                    vc.options = options;
                    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                    [tabs_array addObject:nav];
                }
            } else {
                if([VC.url isEqualToString:url]){
                    // Do nothing
                    tabFound = YES;
                } else {
                    UINavigationController *nav = tabController.viewControllers[i];
                    UIViewController<RussianDollView> *vc = [[nav viewControllers] firstObject];
                    vc.url = url;
                    vc.options = options;
                }
            }
        }
        
        if(firstTime){
            tabController.viewControllers = tabs_array;
        }
        
        for(int i = 0 ; i < maxTabCount ; i++){
            NSDictionary *tab = tabs[i];
            [self setTabBarItem: [tabController.tabBar.items objectAtIndex:i] withTab:tab];
        }
        
        
        // Warn that at least one of the tab bar items should contain the same URL as the currently visible URL
        if(!tabFound){
            [[Jason client] call:@{@"type": @"$util.alert",
                                   @"options": @{ @"title": @"Warning", @"description": @"The tab bar should contain at least one item with the same URL as the currently visible view" }}];
        }
        
        tabController.tabBar.hidden = NO;
    } else {
        tabController.tabBar.hidden = YES;
    }
}

- (BOOL)tabBarController:(UITabBarController *)theTabBarController shouldSelectViewController:(UIViewController *)viewController{
   
    NSUInteger indexOfTab = [theTabBarController.viewControllers indexOfObject:viewController];
    if(VC.rendered && VC.rendered[@"footer"] && VC.rendered[@"footer"][@"tabs"] && VC.rendered[@"footer"][@"tabs"][@"items"]){
        NSArray *tabs = VC.rendered[@"footer"][@"tabs"][@"items"];
        NSDictionary *selected_tab = tabs[indexOfTab];
        
        if(selected_tab[@"href"]){
            NSString *transition = selected_tab[@"href"][@"transition"];
            NSString *view = selected_tab[@"href"][@"view"];
            if(transition){
                if([transition isEqualToString:@"modal"]){
                    [self go: selected_tab[@"href"]];
                    return NO;
                }
            }
            if(view){
                if([view isEqualToString:@"web"] || [view isEqualToString:@"app"]){
                    [self go: selected_tab[@"href"]];
                    return NO;
                }
            }
        } else if(selected_tab[@"action"]){
            [self call:selected_tab[@"action"]];
            return NO;
        }
    }
    
    return YES;
}

- (void)tabBarController:(UITabBarController *)theTabBarController didSelectViewController:(UIViewController *)viewController {
   
    
    // 2. Then go on to updating the nav and VC
    // For updating tabbar whenever user taps on an item (The view itself won't reload)
    navigationController = (UINavigationController *) viewController;
    VC = navigationController.viewControllers.lastObject;
    
    if(VC.parser){
        NSDictionary *body_parser = VC.parser[@"body"];
        if(body_parser){
            if(body_parser[@"footer"] && body_parser[@"footer"][@"tabs"]){
                // Use this
                [self setupTabBar:body_parser[@"footer"][@"tabs"]];
            } else {
                // Deprecated
                [self setupTabBar:body_parser[@"tabs"]];
            }
        }
    }
}
- (void)setTabBarItem:(UITabBarItem *)item withTab: (NSDictionary *)tab{
    NSString *image = tab[@"image"];
    NSString *text = tab[@"text"];
    NSString *badge = tab[@"badge"];
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    if(text){
        [item setTitle:text];
    } else {
        [item setTitle:@""];
    }
    if(image){
        if(text){
            [item setImageInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
        } else {
            [item setImageInsets:UIEdgeInsetsMake(7.5, 0, -7.5, 0)];
        }
        [manager downloadImageWithURL:[NSURL URLWithString:image]
                              options:0
                             progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                             }
                            completed:^(UIImage *i, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                if (i) {
                                    CGFloat width = 0;
                                    CGFloat height = 0;
                                    if(tab[@"style"] && tab[@"style"][@"width"]){
                                        width = [tab[@"style"][@"width"] floatValue];
                                    }
                                    if(tab[@"style"] && tab[@"style"][@"height"]){
                                        height = [tab[@"style"][@"height"] floatValue];
                                    }
                                    
                                    if(width == 0 && height !=0){
                                        width = height;
                                    } else if (width != 0 && height ==0){
                                        height = width;
                                    } else if (width == 0 && height ==0){
                                        width = 30;
                                        height = 30;
                                    }
                                    
                                    UIImage *newImage = [JasonHelper scaleImage:i ToSize:CGSizeMake(width,height)];
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [item setImage:newImage];
                                    });
                                }
                            }];

    } else {
        [item setTitlePositionAdjustment:UIOffsetMake(0.0, -18.0)];
    }
    if(badge){
        [item setBadgeValue:badge];
    }
}

# pragma mark - View Event Handlers

/*************************************************************
 
 ## Event Handlers Rule
 
 1. Pick only ONE Between $load and $show.
    - It's because currently action call chains are single threaded on Jason.
    - If you include both, only $load will be triggered.
 2. Use $show if you want to keep content constantly in sync without manually refreshing ($show gets triggered whenever the view shows up while you're in the app, either from a parent view or coming back from a child view).
 3. Use $load if you want to trigger ONLY when the view loads (for populating content once)
    - You still may want to implement a way to refresh the view manually. You can:
        - add some component that calls "$network.request" or "$reload" when touched
        - add "$pull" event handler that calls "$network.request" or "$reload" when user makes a pull to refresh action
 4. Use $foreground to handle coming background ($show only gets triggered WHILE you're on the app)
 
*************************************************************/

- (void)onShow{
    NSDictionary *events = [VC valueForKey:@"events"];
    if(events){
        if(!events[@"$load"]){
            if(events[@"$show"]) {
                [self call:events[@"$show"]];
            }
        }
    }
}
- (void)onLoad{
    NSDictionary *events = [VC valueForKey:@"events"];
    if(events){
        if(events[@"$load"]){
            if(!VC.contentLoaded){
                [self call:events[@"$load"]];
            }
        }
    }
    // onLoad calls onShow by default
    // so that $show will be triggered even if $load doesn't exit
    [self onShow];
    VC.contentLoaded = YES;
}
- (void)onBackground{
    isForeground = NO;
    NSDictionary *events = [VC valueForKey:@"events"];
    if(events){
        if(events[@"$background"]){
            [self call:events[@"$background"]];
        }
    }
}
- (void)onForeground{
    // Clear the app icon badge
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    // Don't trigger if the view has already come foreground once (because this can be triggered by things like push notification / geolocation alerts)
    if(!isForeground){
        NSDictionary *events = [VC valueForKey:@"events"];
        if(events){
            if(events[@"$foreground"]){
                [self call:events[@"$foreground"]];
            }
        }
    }
    isForeground = YES;
}
- (void)onRemoteNotification: (NSDictionary *)payload{
    NSDictionary *events = [VC valueForKey:@"events"];
    if(events){
        if(events[@"$notification.remote"]){
            [self call:events[@"$notification.remote"] with: @{@"$jason": payload}];
        }
    }
}

- (void)onRemoteNotificationDeviceRegistered: (NSString *)device_token{
    NSDictionary *events = [VC valueForKey:@"events"];
    if(events){
        if(events[@"$notification.registered"]){
            [self call:events[@"$notification.registered"] with: @{@"$jason": @{@"device_token": device_token}}];
        }
    }

}

# pragma mark - View Linking
- (void)go:(NSDictionary *)href{
    /*******************************
     *
     * Linking View to another View
     *
     *******************************/
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *view = href[@"view"];
        NSString *transition = href[@"transition"];
        NSString *fresh = href[@"fresh"];
        JasonMemory *memory = [JasonMemory client];
        if([transition isEqualToString:@"root"]){
            [self start: nil];
            return;
        }
        
        if([view.lowercaseString isEqualToString:@"web"]){
            /***************************************
             *
             * WebView using SFSafariViewController
             *
             ***************************************/
            NSString *encoded_url = [JasonHelper linkify:href[@"url"]];
            NSURL *URL = [NSURL URLWithString:encoded_url];
            [self unlock];
            SFSafariViewController *vc = [[SFSafariViewController alloc] initWithURL:URL];
            
            if([transition isEqualToString:@"modal"]){
                UINavigationController *newNav = [[UINavigationController alloc]initWithRootViewController:vc];
                [newNav setNavigationBarHidden:YES animated:NO];
                [navigationController presentViewController:newNav animated:YES completion:^{ }];
            } else {
                [navigationController presentViewController:vc animated:YES completion:^{ }];
                
            }
        } else if ([view.lowercaseString isEqualToString:@"app"] || [view.lowercaseString isEqualToString:@"external"]){
            /****************************************************************************
             *
             * Open external URL scheme such as "sms:", "mailto:", "twitter://", etc.
             *
             ****************************************************************************/
            NSString *url = href[@"url"];
            if(memory._register && memory._register.count > 0){
                NSDictionary *parsed_href = [JasonHelper parse: [JasonMemory client]._register with:href];
                url = parsed_href[@"url"];
            }
            if(url){
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
            }
            [self unlock];
        } else {
            if(!view || (view && [view.lowercaseString isEqualToString:@"jason"])){
               // Jason View
                NSString *viewClass = @"JasonViewController";
                if([transition isEqualToString:@"replace"]){
                    /****************************************************************************
                     *
                     * Replace the current view
                     *
                     ****************************************************************************/
                    [self unlock];
                    if(href){
                        NSString *new_url;
                        NSDictionary *new_options;
                        if(href[@"url"]){
                            new_url = [JasonHelper linkify:href[@"url"]];
                        }
                        if(href[@"options"]){
                            new_options = [JasonHelper parse:memory._register with:href[@"options"]];
                        } else {
                            new_options = @{};
                        }
                        [self start:@{@"url": new_url, @"loading": @YES, @"options": new_options}];
                    }
                    
                } else if([transition isEqualToString:@"modal"]){
                    /****************************************************************************
                     *
                     * Modal Transition
                     *
                     ****************************************************************************/
                    
                    Class v = NSClassFromString(viewClass);
                    UIViewController<RussianDollView> *vc = [[v alloc] init];
                    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                    UITabBarController *tab = [[UITabBarController alloc] init];
                    tab.viewControllers = @[nav];
                    
                    vc.isModal =YES;
                    
                    if(fresh){
                        vc.fresh = YES;
                    } else {
                        vc.fresh = NO;
                    }
                    if(href){
                        if(href[@"url"]){
                            NSString *url = [JasonHelper linkify:href[@"url"]];
                            if([vc respondsToSelector:@selector(url)]) vc.url = url;
                        }
                        if(href[@"loading"]){
                            vc.loading = [href[@"loading"] boolValue];
                        }
                        if([vc respondsToSelector: @selector(options)]) vc.options = href[@"options"];
                        [self unlock];
                    }
                    
                    UITabBarController *root = (UITabBarController *)[[[UIApplication sharedApplication] keyWindow] rootViewController];
                    while (root.presentedViewController) {
                        root = (UITabBarController *)root.presentedViewController;
                    }

                    // Hide tab bar before opening modal
                    vc.extendedLayoutIncludesOpaqueBars = YES;
                    root.tabBar.hidden = YES;
                    
                    [root presentViewController:tab animated:YES completion:^{
                    }];
                    CFRunLoopWakeUp(CFRunLoopGetCurrent());
                } else {
                    /****************************************************************************
                     *
                     * [Default] Push transition
                     *
                     ****************************************************************************/
                    Class v = NSClassFromString(viewClass);
                    UIViewController<RussianDollView> *vc = [[v alloc] init];
                    if(href){
                        if(href[@"url"]){
                            NSString *url = [JasonHelper linkify:href[@"url"]];
                            vc.url = url;
                        }
                        if(href[@"options"]){
                            vc.options = [JasonHelper parse:memory._register with:href[@"options"]];
                        }
                        if(href[@"loading"]){
                            vc.loading = [href[@"loading"] boolValue];
                        }
                        
                        if(fresh){
                            vc.fresh = YES;
                        } else {
                            vc.fresh = NO;
                        }
                        
                        [self unlock];
                    }
                    if(tabController.tabBar.hidden){
                        vc.hidesBottomBarWhenPushed = YES;
                        vc.extendedLayoutIncludesOpaqueBars = YES;
                        tabController.tabBar.hidden = YES;
                    } else {
                        if([transition isEqualToString:@"fullscreen"]){
                            vc.hidesBottomBarWhenPushed = YES;
                        } else {
                            vc.hidesBottomBarWhenPushed = NO;
                        }
                    }
                    [navigationController pushViewController:vc animated:YES];
                }
            }
            else {
                
                /****************************************************************************
                 
                ** Custom ViewControllers
                 
                1. Opening your custom view from Jason view
                    1.1. Using storyboard
                        To transition from Jasonette to Your custom view controller,
                        Simply declare the view controller class name as:
                            
                            [Storyboard Name].[The viewcontroller's storyboard ID]
             
                        [Example]
                            if your storyboard is named "MainStoryboard.storyboard", and the viewcontroller has the id "LiveStreamView",
                 
                            simply attach the following href to any component you desire:
                 
                            {
                                "type": "label",
                                "text": "Start livestreaming",
                                "href": {
                                    "view": "MainStoryboard.LiveStreamView"
                                }
                            }
                    1.2. Without storyboard
                        To transition from Jasonette to Your custom view controller,
                        Simply declare the view controller class name as "view" attribute.
             
                        [Example]
                            if you have a view controller class called "LiveStreamViewController",
                            simply attach the following href to any component you desire:
                 
                            {
                                "type": "label",
                                "text": "Start livestreaming",
                                "href": {
                                    "view": "LiveStreamViewController"
                                }
                            }
                            
                    1.3. Passing parameters
                        To pass parameters to your custom view controller,
             
                        A. just add a property called "jason" to your view controller like this:
             
                            @property (nonatomic, strong) NSDictionary *jason
             
                        B. Then pass values via 'options' attribute like this:
             
                            {
                                "type": "label",
                                "text": "Make a payment",
                                "href": {
                                    "view": "PaymentViewController",
                                    "options": {
                                        "product_id": "dnekfsl",
                                        "user_id": "3kz"
                                    }
                                }
                            }
            
                        C. Then use the jason NSDictionary from your custom view controller
                 
                            // PaymentViewController.m
                            #import "PaymentViewController.h"
                            @implementation PaymentViewController
                              ....
                              - (void)viewDidLoad {
                                [super viewDidLoad];
                                NSString *product_id = self.jason[@"product_id"];
                                NSString *user_id = self.jason[@"user_id"];

                                // do some customization with product_id and user_id
                              }
                              ....
                            @end
             
                2. Opening Jason view from your custom viewcontrollers
             
                    Opening Jasonette from your viewcontrollers is same as opening any other viewcontrollers.
             
                    A. First, include JasonViewController.h in your viewcontroller
             
                       #import "JasonViewController.h"
             
                    B. To display Jasonette view with push transition:
             
                        JasonViewController *vc = [[JasonViewController alloc] init];
                        vc.url = @"https://jasonbase.com/things/jYJ.json";
                        [self.navigationViewController pushViewController:vc animated:YES];
                 
                    C. To present Jasonette view as modal:
             
                        JasonViewController *vc = [[JasonViewController alloc] init];
                        vc.url = @"https://jasonbase.com/things/jYJ.json";
                        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                        [self.navigationController presentViewController:nav animated:YES completion:nil];
                 
                 
                 ****************************************************************************/
                
                // Instantiate ViewController
                UIViewController<RussianDollView> *vc;
                UINavigationController *nav;
                NSArray *tokens = [href[@"view"] componentsSeparatedByString:@"."];
                // 1. via "view": "[STORYBOARD_NAME].[VIEWCONTROLLER_STORYBOARD_ID]" format
                if(tokens.count == 2) {
                    NSString *storyboardName = tokens[0];
                    NSString *storyboardIdentifier = tokens[1];
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
                    vc = [storyboard instantiateViewControllerWithIdentifier:storyboardIdentifier];
                    nav = vc.navigationController;
                }
                // 2. via "view": "[VIEWCONTROLLER_CLASSNAME]" format
                else {
                    Class CustomViewController = NSClassFromString(href[@"view"]);
                    vc = [[CustomViewController alloc] init];
                    nav = [[UINavigationController alloc] initWithRootViewController:vc];
                }
                
                
                // Option 1. Present as modal
                if([transition isEqualToString:@"modal"]){
                    if(href[@"options"]){
                        if([vc respondsToSelector: @selector(jason)]) {
                            [vc setValue:href[@"options"] forKey:@"jason"];
                        }
                    }
                    [self unlock];
                    [navigationController presentViewController:nav animated:YES completion:^{
                    }];
                    CFRunLoopWakeUp(CFRunLoopGetCurrent());
                }
                // Option 2. Push transition
                else {
                    if(href[@"options"]){
                        if([vc respondsToSelector: @selector(jason)]) {
                            [vc setValue:href[@"options"] forKey:@"jason"];
                        }
                    }
                    [self unlock];
                    [navigationController pushViewController:vc animated:YES];
                }
            }
            
        }
    });
}

# pragma mark - Action invocation related
/**********************************************************************************************************************
*
* Generates 'options' object to be passed to the next action in the call chain by looking at the stack, register, etc.
*
*********************************************************************************************************************/
- (NSDictionary *)options{
    JasonMemory *memory = [JasonMemory client];
    
    /*********************************************************************************************************
    *
    * Step 1.
    *
    * "IF" clause handling
    *
    * If the stack contains an array, it may mean it's an if clause
    *
    * (ex)
    *
    *   [
    *        {
    *            "{{#if result.length > 0}}": {...}
    *        },
    *        {
    *            "{{#else}}": {...}
    *        }
    *    ]
    *
    * In this case we need to fill it out once to reduce it down to the actual expression to be executed
    *
    ********************************************************************************************************/
    NSDictionary *reduced_stack;
    if([memory._stack isKindOfClass:[NSArray class]]){
        reduced_stack = [self filloutTemplate: memory._stack withData: memory._register];
    } else {
        reduced_stack = [memory._stack mutableCopy];
    }
    
    /*********************************************************************************************************
    *
    * Step 2. Now that the if conditionals are out of the way, actually fill out the result options template with register
    *
    ********************************************************************************************************/
    if(reduced_stack[@"options"]){
        return [self filloutTemplate: reduced_stack[@"options"] withData: memory._register];
    } else {
        return nil;
    }
    
}
- (void)exec{
    @try{
        JasonMemory *memory = [JasonMemory client];
        
        // need to set the 'executing' state to NO initially
        // until it actually starts executing
        memory.executing = NO;
        
        if(memory._stack && memory._stack.count > 0){
            
            /****************************************************
            * First, handle conditional cases
            * If the stack contains an array, it must be a conditional. (#if)
            # So run it through 'options' method to generate an actual stack
            ****************************************************/
            if([memory._stack isKindOfClass:[NSArray class]]){
                memory._stack = [self filloutTemplate: memory._stack withData: memory._register];
            }
            
            
            NSString *trigger = memory._stack[@"trigger"];
            NSString *type = memory._stack[@"type"];
            
            // Type 1. Action Call by name (trigger)
            if(trigger)
            {
                NSString *action_name = memory._stack[@"trigger"];
                id triggered_action = [[VC valueForKey:@"events"] valueForKey:action_name];
                NSDictionary *action;
                if([triggered_action isKindOfClass:[NSArray class]]){
                    action = [self filloutTemplate:triggered_action withData:memory._register];
                } else {
                    action = triggered_action;
                }
                
                if(action && action.count > 0){
                    NSDictionary *options = [self options];
                    if(options){
                        memory._stack = [JasonHelper parse: options with:action];
                    } else {
                        memory._stack = action;
                    }
                    [self exec];
                }
            }
            
            // Type 2. Action Call by type (normal)
            else if(type)
            {
                NSArray *tokens = [type componentsSeparatedByString:@"."];
                
                // Jason Core actions: "METHOD" format => Within Jason.m
                if(tokens.count == 1)
                {
                    if(type.length > 1 && [type hasPrefix:@"$"]){
                        NSString *actionName = [type substringFromIndex:1];
                        SEL method = NSSelectorFromString(actionName);
                        self.options = [self options];
                        
                        // Set 'executing' to YES to prevent other actions from being accidentally executed concurrently
                        memory.executing = YES;
                        
                        [self performSelector:method];
                    }
                } else if ([type hasPrefix:@"@"]) {
                    /*
                     * Call a 'plug in method'.  We now take the full type w/o the '@‘ prefix
                     * and try to load that class.  This gives us more freedom with class names
                     * and allows for implementations in Swift -- Swift "classes" always have their
                     * module name compiled in.
                     *
                     * Examples:
                     *
                     * {
                     *    "type": "@MyActionClass.demo",
                     *    "options": {
                     *        "foo": "42"
                     *    }
                     * }
                     *
                     * Or for Swift:
                     *
                     * {
                     *    "type": "@MyActionModule.SomeClassName.demo",
                     *    "options": {
                     *        "foo": "42"
                     *    }
                     * }
                     *
                     */

                    // skip prefix to get module path
                    NSString *plugin_path = [type substringFromIndex:1];
                    NSLog(@"Plugin: plugin path: %@", plugin_path);

                    // The module name is the plugin path w/o the last part
                    // e.g. "MyModule.MyClass.demo" -> "MyModule.MyClass"
                    //      "MyClass.demo" -> "MyClass"
                    NSArray *mod_tokens = [plugin_path componentsSeparatedByString:@"."];
                    if (mod_tokens.count > 1) {
                        NSString *module_name = [[mod_tokens subarrayWithRange:NSMakeRange(0, mod_tokens.count -1)]
                                                  componentsJoinedByString:@"."];
                        NSString *action_name = [mod_tokens lastObject];

                        NSLog(@"Plugin: module name: %@", module_name);
                        NSLog(@"Plugin: action name: %@", action_name);

                        Class PluginClass = NSClassFromString(module_name);
                        if (PluginClass) {
                            NSLog(@"Plugin: class: %@", PluginClass);

                            // Initialize Plugin
                            module = [[PluginClass alloc] init];  // could go away if we had some sort of plug in registration

                            [[NSNotificationCenter defaultCenter]
                                    postNotificationName:plugin_path
                                                  object:self
                                                  userInfo:@{
                                      @"vc": VC,
                                      @"plugin_path": plugin_path,
                                      @"action_name": action_name,
                                      @"options": [self options]
                                  }];

                        } else {
                            [[Jason client] call:@{@"type": @"$util.banner",
                                                   @"options": @{
                                                           @"title": @"Error",
                                                           @"description":
                                                               [NSString stringWithFormat:@"Plugin class '%@' doesn't exist.", module_name]
                                                           }}];

                        }
                    } else {
                        // ignore error: "@ModuleName" -> missing action name
                    }
                }

                // Module actions: "$CLASS.METHOD" format => Calls other classes
                else
                {
                    
                    NSString *className = tokens[0];
                    
                    // first take a look at the json file to resolve classname
                    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
                    NSString *jrjson_filename=[NSString stringWithFormat:@"%@/%@.json", resourcePath, className];
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    NSString *resolved_classname = nil;
                    if ([fileManager fileExistsAtPath:jrjson_filename]) {
                        NSError *error;
                        NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath:jrjson_filename];
                        [inputStream open];
                        NSDictionary *json = [NSJSONSerialization JSONObjectWithStream: inputStream options:kNilOptions error:&error];
                        [inputStream close];
                        if(json[@"classname"]){
                            resolved_classname = json[@"classname"];
                        }
                    } else {
                        if(className.length > 1 && [className hasPrefix:@"$"]){
                            resolved_classname = [[className substringFromIndex:1] capitalizedString];
                            /*
                             
                             CLASS name Needs to follow the following convention:
                             
                             "Jason[CLASSNAME]Action"
                             
                             example: JasonMediaAction, JasonAudioAction, JasonNetworkAction, etc.
                             
                             */

                            resolved_classname = [NSString stringWithFormat:@"Jason%@Action", resolved_classname];
                        }
                    }
                    
                    if(resolved_classname){
                        Class ActionClass = NSClassFromString(resolved_classname);
                        if(ActionClass){
                            // This means I have implemented this already
                            NSString *methodName = tokens[1];
                            SEL method = NSSelectorFromString(methodName);
                            
                            NSDictionary *options = [self options];
                            
                            module = [[ActionClass alloc] init];
                            if([module respondsToSelector:@selector(VC)]) [module setValue:VC forKey:@"VC"];
                            if([module respondsToSelector:@selector(options)]) [module setValue:options forKey:@"options"];
                            
                            // Set 'executing' to YES to prevent other actions from being accidentally executed concurrently
                            memory.executing = YES;
                            
                            [module performSelector:method];
                        } else {
                            [[Jason client] call:@{@"type": @"$util.banner",
                                                   @"options": @{
                                                       @"title": @"Error",
                                                       @"description": [NSString stringWithFormat:@"%@ class doesn't exist.", resolved_classname]
                                                   }}];
                        }
                    }
                }
                
                
                // If the stack doesn't include any action to take after success, just finish
                if(!memory._stack[@"success"] && !memory._stack[@"error"]){
                    // VC.contentLoaded is NO if the action is $reload (until it returns)
                    if(VC.contentLoaded) [self finish];
                }
            }
            else
            {
                [self unlock];
            }
        } else {
            /****************************************************
            *
            * Stack empty. Time to finish!
            *
            ****************************************************/
            [self finish];
        }
    }
    @catch(NSException *e){
        NSLog(@"ERROR..");
        NSLog(@"JasonStack : %@", [JasonMemory client]._stack);
        NSLog(@"Register : %@", [JasonHelper stringify:[JasonMemory client]._register]);
        [self call:@{@"type": @"$util.banner", @"options": @{@"title": @"Error", @"description": @"Something went wrong. Please try again"}}];
        [self finish];
    }
}
- (void)exception{
    [[JasonMemory client] exception];
    [self exec];
}
- (void)next{
    [[JasonMemory client] pop];
    [self exec];
}
- (void)finish{
    [self unlock];
}
- (void)unlock{
    [self loading:NO];
    [JasonMemory client]._stack = @{};
    [JasonMemory client]._register = @{};
    [JasonMemory client].locked = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"finishRefreshing" object:nil];
    VC.view.userInteractionEnabled = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"unlock" object:nil];
    
    // In case oauth was in process, set it back to No
    self.oauth_in_process = NO;

}


# pragma mark - Helpers, Delegates & Misc.

- (void)cache_view{
    // Experimental: Store cache content for offline
    if(VC.original && VC.rendered && VC.original[@"$jason"][@"head"][@"offline"]){
        if(![[VC.rendered description] containsString:@"{{"] && ![[self.options description] containsString:@"}}"]){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NSString *normalized_url = [self normalized_url];
                normalized_url = [normalized_url stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *path = [documentsDirectory stringByAppendingPathComponent:normalized_url];
                
                NSMutableDictionary *to_store = [VC.original mutableCopy];
                to_store[@"$jason"] = @{@"body": VC.rendered};
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:to_store];
                [data writeToFile:path atomically:YES];
            });
        }
    }
}
- (NSString *)normalized_url{
    NSString *normalized_url = [VC.url lowercaseString];
    normalized_url = [normalized_url stringByAppendingString:[NSString stringWithFormat:@"|%@", VC.options]];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[/:]" options:NSRegularExpressionCaseInsensitive error:nil];
    normalized_url = [regex stringByReplacingMatchesInString:normalized_url options:0 range:NSMakeRange(0, [normalized_url length]) withTemplate:@"_"];
    normalized_url = [[normalized_url componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
    return normalized_url;
}
// Delegate for handling snapshot
- (void)vision:(PBJVision *)vision capturedPhoto:(NSDictionary *)photoDict error:(NSError *)error
{
    if (error) {
        [[Jason client] error];
        return;
    }
    
    // save to library
    NSData *photoData = photoDict[PBJVisionPhotoJPEGKey];
    NSDictionary *metadata = photoDict[PBJVisionPhotoMetadataKey];
    NSString *contentType = @"image/jpeg";
    NSString *dataFormatString = @"data:image/jpeg;base64,%@";
    
    UIImage *snapshot = [UIImage imageWithData:photoData];
    VC.background = [[UIImageView alloc] initWithFrame:[VC.view bounds]];
    VC.background.contentMode = UIViewContentModeScaleAspectFill;
    [VC.view addSubview:VC.background];
    [VC.view sendSubviewToBack:VC.background];
    ((UIImageView*)VC.background).image = snapshot;
    
    UIImage *image = [JasonHelper takescreenshot];
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    
    NSString* dataString = [NSString stringWithFormat:dataFormatString, [imageData base64EncodedStringWithOptions:0]];
    NSURL* dataURI = [NSURL URLWithString:dataString];
    [[Jason client] success:@{@"data": imageData, @"data_uri": dataURI.absoluteString, @"metadata": metadata, @"content_type" :contentType}];
}

@end
