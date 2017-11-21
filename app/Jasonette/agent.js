$agent={
  callbacks: {},

  // Make requests to another agent
  request: function(rpc, callback) {

    // set nonce to only respond to the return value I requested for
    var nonce = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15)
    $agent.callbacks[nonce] = function(data) {
      callback(data)
    }

    // send message
    window.webkit.messageHandlers["%@"].postMessage({
      type: "request",
      rpc: rpc,
      nonce: nonce
    })

  },
    
  // Return response to Jasonette or the caller agent
  response: function(data) {
    window.webkit.messageHandlers["%@"].postMessage({
      type: "response",
      data: data
    })
  },

  // One way event fireoff to Jasonette
  trigger: function(event, options) {
    window.webkit.messageHandlers["%@"].postMessage({
      type: "event",
      event: event,
      options: options
    })
  },
    
  // Trigger Jasonette href
  href: function(href) {
    window.webkit.messageHandlers["%@"].postMessage({
      type: "href",
      options: href
    })
  }
}
