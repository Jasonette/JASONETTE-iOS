//
//  JasonAgentAction.m
//  Jasonette
//
//  Copyright © 2017 Jasonette. All rights reserved.
//

#import "JasonAgentAction.h"

@implementation JasonAgentAction


/*************************************
Jasonette => Agent Remote Function Call
 
 
1. Write an HTML or JS for a container
 
In this case, we'll store the following code under file://app.js

var whoareyou = function(firstname, lastname) {
    JASON.call({
        "type": "$util.alert",
        "options": {
            "title": "Identification",
            "description": "The name is " + lastname + ". " + firstname + " " + lastname
        }
    });
}
 
2. Set up the agent with $jason.head.agents

{
	"$jason": {
		"head": {
			"agents": {
                "007": {
                    "url": "file://app.js"
                }
			}
		}
	}
}

3. Call any function inside the agent

{
    "type": "$agent.request",
    "options": {
        "id": "007",
        "method": "whoareyou",
        "params": ["James", "Bond"]
    }
}

*************************************/

- (void) request {
    JasonAgentService *service = [Jason client].services[@"JasonAgentService"];
    [service request: self.options];
}
@end
