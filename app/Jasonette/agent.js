$agent={
  callbacks: {},

  interface: {},

  /* Make requests to another agent */
  request: function(rpc, callback) {

    /* set nonce to only respond to the return value I requested for */
    var nonce = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);

    $agent.callbacks[nonce] = function(data) {
        /* Execute the callback */
        callback(data);

        /* Delete itself to free up memory */
        delete $agent.callbacks[nonce];
    };

    /* send message */
    $agent.interface.postMessage({
      request: { data: rpc, nonce: nonce }
    });

  },

  /* Return response to Jasonette or the caller agent */
  response: function(data) {
    $agent.interface.postMessage({
      response: { data: data }
    });
  },

  /* One way event fireoff to Jasonette */
  trigger: function(event, options) {
    $agent.interface.postMessage({
      trigger: { name: event, data: options }
    });
  },

  /* Trigger Jasonette href */
  href: function(href) {
    $agent.interface.postMessage({
      href: { data: href }
    });
  }
};


