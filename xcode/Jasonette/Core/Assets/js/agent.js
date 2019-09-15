/**
 * agent.js
 * Defines the $agent object that will be injected in every webview
 */
const $agent = {
    callbacks: {},
    
    interface: {}
};

// Make requests to another agent
$agent.request = function(rpc, callback) {
    
    // set nonce to only respond to the return value I requested for
    var nonce = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
    
    $agent.callbacks[nonce] = function(data) {
        // Execute the callback
        callback(data);
        
        // Delete itself to free up memory
        delete $agent.callbacks[nonce];
    };
    
    // Send message
    $agent.interface.postMessage({
                                 request: { data: rpc, nonce: nonce }
                                 });
    
};

// Return response to Jasonette or the caller agent
$agent.response = function(data) {
    $agent.interface.postMessage({
                                 response: { data: data }
                                 });
};

// One way event fireoff to Jasonette
$agent.trigger = function(event, options) {
    $agent.interface.postMessage({
                                 trigger: { name: event, data: options }
                                 });
};

// Trigger Jasonette href
$agent.href = function(href) {
    $agent.interface.postMessage({
                                 href: { data: href }
                                 });
};

// Trigger Jasonette logger
$agent.log = function(level = 'debug', ...args) {
    $agent.interface.postMessage({
                                 log: {level, arguments:args}
                                 });
};

$agent.logger = {};
$agent.logger.log = function(...args) {
    $agent.log('debug', args);
};

$agent.logger.debug = function(...args) {
    $agent.log('debug', args);
};

$agent.logger.info = function(...args) {
    $agent.log('info', args);
};

$agent.logger.warn = function(...args) {
    $agent.log('warn', args);
};

$agent.logger.error = function(...args) {
    $agent.log('error', args);
};
