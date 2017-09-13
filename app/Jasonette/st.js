(function($context) {

  var root; // root context

  var Helper = {
    is_template: function(str){
      var re = /\{\{(.+)\}\}/g;
      return re.test(str);
    },
    is_array: function(item) {
      return (
          Array.isArray(item) || 
          (!!item &&
            typeof item === "object" && typeof (item.length) === "number" && 
            (item.length === 0 || (item.length > 0 && (item.length - 1) in item))
          )
      );
    },
    resolve: function(o, path, new_val){
      // 1. takes any object
      // 2. Finds thes subtree based on path
      // 3. sets the value to new_val
      // 4. returns the object;
      if(path && path.length > 0){
        func = Function('new_val', "with(this){this" + path + "=new_val; return this;}").bind(o);
        return func(new_val);
      } else {
        o = new_val;
        return o;
      }
    }
  }

  var Conditional = {
    run: function(template, data){
      // expecting template as an array of objects,
      // each of which contains "#if", "#elseif", "else" as key

      // item should be in the format of:
      // {'#if item': 'blahblah'}

      // Step 1. get all the conditional keys of the template first.
      // Step 2. then try evaluating one by one until something returns true
      // Step 3. if it reaches the end, the last item shall be returned

      var cannot_parse = false;
      for(var i = 0 ; i < template.length; i++){
        var item = template[i];
        var keys = Object.keys(item);
        // assuming that there's only a single kv pair for each item
        var key = keys[0];


        var func = TRANSFORM.tokenize(key)
        if(func.name == "#if" || func.name == "#elseif"){
          var expression = func.expression;
          var res = TRANSFORM.fillout(data, "{{" + expression + "}}");

          if(res == ("{{" + expression + "}}")){
            // if there was at least one item that was not evaluatable,
            // we halt parsing and return the template;
            return template;
          } else {
            if(res){
              // run the current one and return
              return TRANSFORM.run(item[key], data);
            } else {
              // res was falsy. Ignore this branch and go on to the next item
            }
          }
        } else {
          // #else
          // if you reached this point, it means:
          //  1. there were no non-evaluatable expressions
          //  2. Yet all preceding expressions evaluated to falsy value
          //  Therefore we run this branch
          return TRANSFORM.run(item[key], data);
        }
      }

      // if you've reached this point, it means nothing matched.
      // so return null
      return null;
    },
    is: function(template){

      // TRUE ONLY IF it's in a correct format.
      // Otherwise return the original template

      // Condition 0. Must be an array
      // Condition 1. Must have at least one item
      // Condition 2. Each item in the array should be an object of a single key/value pair
      // Condition 3. starts with #if
      // Condition 4. in case there's more than two items, everything between the first and the last item should be #elseif
      // Condition 5. in case there's more than two items, the last one should be either "#else" or "#elseif"

      if(!Helper.is_array(template)){
        // Condition 0, it needs to be an array to be a conditional
        return false;
      }

      // Condition 1.
      // Must have at least one item
      if(template.length == 0){
        return false;
      }

      // Condition 2.
      // Each item in the array should be an object
      // , and  of a single key/value pair
      var containsValidObjects = true;
      for(var i = 0 ; i < template.length ; i++){
        var item = template[0];
        if(typeof item !== "object"){
          containsValidObjects = false;
          break; 
        }
        if(Object.keys(item).length != 1){
          // first item in the array has multiple key value pairs, so invalid.
          containsValidObjects = false;
          break;
        } 
      }
      if(!containsValidObjects){
        return false;
      }

      // Condition 3.
      // the first item should have #if as its key
      // the first item should also contain an expression
      var first = template[0];
      for(var key in first){
        var func = TRANSFORM.tokenize(key);
        if(!func){
          return false;
        }
        if(!func.name){
          return false;
        }

        // "{{#if }}"
        if(!func.expression || func.expression.length == 0){
          return false;
        }

        var func_name = func.name.toLowerCase();
        if(func_name != "#if"){
          return false;
        }
      }

      if(template.length == 1){
        // If we got this far and the template has only one item, it means 
        // template had one item which was "#if" so it's valid
        return true;
      }



      // Condition 4.
      // in case there's more than two items, everything between the first and the last item should be #elseif

      var they_are_all_elseifs = true;
      for(var i = 1 ; i < template.length-1 ; i++){
        var item = template[i];
        for(var key in item){
          var func = TRANSFORM.tokenize(key);
          var func_name = func.name.toLowerCase();
          if(func_name != "#elseif"){
            they_are_all_elseifs = false;
            break;
          }
        }
      }

      if(!they_are_all_elseifs){
        // There was at least one item that wasn't an elseif
        // therefore invalid
        return false;
      }

      // If you've reached this point, it means we have multiple items and everything between the first and the last item
      // are elseifs
      // Now we need to check the validity of the last item

      // Condition 5.
      // in case there's more than one item, it should end with #else or #elseif
      var last = template[template.length-1];
      for(var key in last){
        var func = TRANSFORM.tokenize(key);
        var func_name = func.name.toLowerCase();
        if(func_name != "#else" && func_name != "#elseif"){
          return false;
        }
      }

      // Congrats, if you've reached this point, it's valid
      return true;

    },
  }

  var TRANSFORM = {
    transform: function(template, data, serialized) {
      var selector = null;
      if (/#include/.test(JSON.stringify(template))) {
        selector = function(key, value){ return /#include/.test(key) || /#include/.test(value); };
      }
      var res = SELECT.select(template, selector, serialized)
                .transform(data, serialized)
                .root();
      if (serialized) {
        // needs to return stringified version
        return JSON.stringify(res);
      } else {
        return JSON.parse(JSON.stringify(res));
      }
    },
    tokenize: function(str) {
      // INPUT : string
      // OUTPUT : {name: FUNCTION_NAME:STRING, args: ARGUMENT:ARRAY}
      var re = /\{\{(.+)\}\}/g;
      str = str.replace(re, "$1");
      // str : "#each $jason.items"

      var tokens = str.trim().split(" ");
      // => tokens: ['#each', '$jason.items']

      var func;
      if(tokens.length > 0){
        if(tokens[0][0] == "#"){
          func = tokens.shift();
          // => func: "#each" or "#if"
          // => tokens: ['$jason.items', '&&', '$jason.items.length', '>', '0']

          var expression = tokens.join(' '); 
          // => expression: '$jason.items && $jason.items.length > 0'

          return {name: func, expression: expression};
        }
      }
      return null;
    },
    run: function(template, data) {
      var result;
      if(typeof template == "string"){
        // Leaf node, so call TRANSFORM.fillout()
        if(Helper.is_template(template)){
          var include_re = /\{\{([ ]*#include)[ ]*([^ ]*)\}\}/g
          if(include_re.test(template)){
            var fun = TRANSFORM.tokenize(template);
            if(fun.expression) {
              // if #include has arguments, evaluate it before attaching
              result = TRANSFORM.fillout(data, "{{" + fun.expression + "}}", true);
            } else {
              // shouldn't happen =>
              // {"wrapper": "{{#include}}"}
              result = template;
            }
          } else {
            // non-#include
            result = TRANSFORM.fillout(data, template);
          }
        } else {
          result = template;
        }
      } else if(Helper.is_array(template)){
        if(Conditional.is(template)){
          result = Conditional.run(template, data);
        } else {
          result = [];
          for(var i = 0 ; i < template.length ; i++){
            var item = TRANSFORM.run(template[i], data);
            if(item){
              // only push when the result is not null
              // null could mean #if clauses where nothing matched => In this case instead of rendering "null", should just skip it completely
              // Todo : Distinguish between #if arrays and ordinary arrays, and return null for ordinary arrays
              result.push(item);
            }
          }
        }
      } else if(Object.prototype.toString.call(template) == "[object Object]"){
        // template is an object
        result = {};

        // ## Handling #include
        // This needs to precede everything else since it's meant to be overwritten
        // in case of collision
        var include_re = /\{\{([ ]*#include)[ ]*(.*)\}\}/g
        var include_keys = Object.keys(template).filter(function(key){return include_re.test(key);});
        if(include_keys.length > 0){
        // find the first key with #include
          var fun = TRANSFORM.tokenize(include_keys[0]);
          if(fun.expression) {
            // if #include has arguments, evaluate it before attaching
            result = TRANSFORM.fillout(template[include_keys[0]], "{{" + fun.expression + "}}", true);
          } else {
            // no argument, simply attach the child
            result = template[include_keys[0]];
          }
        }

        var re = /\{\{(.+)\}\}/g;
        for(var key in template){
          // Checking to see if the key contains template..
          // Currently the only case for this are "#each" and "#include"
          if(Helper.is_template(key)){
            var fun = TRANSFORM.tokenize(key);
            if(fun){
              if(fun.name == "#include"){
                // this was handled above (before the for loop) so just ignore
              } else if(fun.name == "#each"){
                // newData will be filled with parsed results
                var newData = TRANSFORM.fillout(data, "{{" + fun.expression + "}}", true);

                // Ideally newData should be an array since it was prefixed by #each
                if(newData && Helper.is_array(newData)){
                  result = [];
                  for(var i = 0 ; i < newData.length ; i++){
                    var item = TRANSFORM.run(template[key], newData[i]);
                    if(item){
                      // only push when the result is not null
                      // null could mean #if clauses where nothing matched => In this case instead of rendering "null", should just skip it completely
                      result.push(item);
                    }
                  }
                } else {
                  // In case it's not an array, it's an exception, since it was prefixed by #each.
                  // This probably means this #each is not for the current variable
                  // For example {{#each items}} may not be an array, but just leave it be, so 
                  // But don't get rid of it,
                  // Instead, just leave it as template
                  // So some other parse run could fill it in later.
                  result = template;
                }
              } // end of #each
            } else { // end of if(fun)
              // If the key is a template expression but aren't either #include or #each, 
              // it needs to be parsed
              var k = TRANSFORM.fillout(data, key);
              var v = TRANSFORM.fillout(data, template[key]);
              if(k !== undefined && v !== undefined){
                result[k] = v;
              }
            }
          } else {
            // Helper.is_template(key) was false, which means the key was not a template (hardcoded string)
            var item = TRANSFORM.run(template[key], data);
            if(item !== undefined){
              result[key] = item;
            }
          }
        }
      } else {
        // number, boolean, etc => Just turn them into string!
        if(template === null){
          return "null";
        } else if(template === undefined){
          return "undefined";
        } else {
          return TRANSFORM.run(template.toString(), data);
        }
      }
      return result;
    },
    fillout: function(data, template, raw) {
      // 1. fill out if possible
      // 2. otherwise return the original
      var replaced = template;
      // Run fillout() only if it's a template. Otherwise just return the original string
      if(Helper.is_template(template)){
        var re = /\{\{(.*?)\}\}/g;

        // variables are all instances of {{ }} in the current expression
        // for example "{{this.item}} is {{this.user}}'s" has two variables: ["this.item", "this.user"]
        var variables = template.match(re);

        if(variables){
          if(raw){
            // 'raw' is true only for when this is called from #each
            // Because #each is expecting an array, it shouldn't be stringified.
            // Therefore we pass template:null,
            // which will result in returning the original result instead of trying to
            // replace it into the template with a stringified version
            replaced = TRANSFORM._fillout({
              variable: variables[0],
              data: data,
              template: null
            });
          } else {
            // Fill out the template for each variable
            for(var i = 0 ; i < variables.length ; i++){
              var variable = variables[i];
              replaced = TRANSFORM._fillout({
                variable: variable,
                data: data,
                template: replaced
              });
            }
          }
        } else {
          return replaced;
        }
      }
      return replaced;
    },
    _fillout: function(options){
      // Given a template and fill it out with passed slot and its corresponding data
      var re = /\{\{(.*?)\}\}/g;
      var full_re = /^\{\{((?!\}\}).)*\}\}$/;

      var variable = options.variable;
      var data = options.data;
      var template = options.template;

      try{
          // 1. Evaluate the variable
          var slot = variable.replace(re, "$1");

          // data must exist. Otherwise replace with blank
          if(data){
            var func;

            // Attach $root to each node so that we can reference it from anywhere
            data["$root"] = root;

            // If the pattern ends with a return statement, but is NOT wrapped inside another function ([^}]*$), it's a function expression
            var match = /function\([ ]*\)[ ]*\{(.*)\}[ ]*$/g.exec(slot);
            if(match){
              func = Function("with(this){" + match[1] + "}").bind(data);
            } else if(/\breturn [^;]+;?[ ]*$/.test(slot) && /return[^}]*$/.test(slot)){
              // Function expression with explicit "return" expression
              func = Function("with(this){" + slot + "}").bind(data);
            } else {
              // Function expression with explicit "return" expression
              // Ordinary simple expression that 
              func = Function("with(this){return (" + slot + ")}").bind(data);
            }
            var evaluated = func();

            if(evaluated){
              // In case of primitive types such as String, need to call valueOf() to get the actual value instead of the promoted object
              evaluated = evaluated.valueOf();
            }

            if (typeof evaluated == "undefined") {
              // it tried to evaluate since the variable existed, but ended up evaluating to undefined
              // (example: var a = [1,2,3,4]; var b = a[5];)
              return template;
            } else {
              // 2. Fill out the template with the evaluated value
              // Be forgiving and print any type, even functions, so it's easier to debug
              if(evaluated){
                // IDEAL CASE : Return the replaced template
                if(template){
                  // if the template is a pure template with no additional static text,
                  // And if the evaluated value is an object or an array, we return the object itself instead of
                  // replacing it into template via string replace, since that will turn it into a string.
                  if(full_re.test(template)){
                    return evaluated; 
                  } else {
                    return template.replace(variable, evaluated);
                  }
                } else {
                  return evaluated;
                }
              } else {
                // Treat false or null as blanks (so that #if can handle it)
                if(template){
                  // if the template is a pure template with no additional static text,
                  // And if the evaluated value is an object or an array, we return the object itself instead of
                  // replacing it into template via string replace, since that will turn it into a string.
                  if(full_re.test(template)){
                    return evaluated; 
                  } else {
                    return template.replace(variable, "");
                  }
                } else {
                  return "";
                }
              }
            }
          }

          // REST OF THE CASES
          // if evaluated is null or undefined,
          // it probably means one of the following:
          //  1. The current data being parsed is not for the current template
          //  2. It's an error
          //
          //  In either case we need to return the original template unparsed.
          //    1. for case1, we need to leave the template alone so that the template can be parsed
          //      by another data set
          //    2. for case2, it's better to just return the template so it's easier to debug
          return template;

      } catch (err){
        return template;
      }
    }
  }



  var SELECT = {
    // current: currently accessed object
    // path: the path leading to this item
    // filter: The filter function to decide whether to select or not
    $val: null,
    $selected: [],
    exec: function(current, path, filter){

      // if current matches the pattern, put it in the selected array
      if(typeof current == "string"){
        // leaf node should be ignored
        // we're lookin for keys only
      } else if(Helper.is_array(current)){
        for(var i=0; i<current.length; i++){
          SELECT.exec(current[i], path+"["+i+"]", filter);
        }
      } else {
        // object
        for(var key in current){
          // "$root" is a special key that links to the root node
          // so shouldn't be used to iterate
          if(key !== "$root") {
            if(filter(key, current[key])){
              var index = SELECT.$selected.length;
              SELECT.$selected.push({
                index: index,
                key: key,
                path: path,
                object: current,
                value: current[key]
              });
            }
            SELECT.exec(current[key], path+"[\""+key+"\"]", filter);
          }
        }
      }
    },

    // returns the object itself
    select: function(obj, filter, serialized){
      // iterate '$selected'
      // 
      /*
      SELECT.$selected = [{
        value {
          "{{#include}}": {
            "{{#each items}}": {
              "type": "label",
              "text": "{{name}}"
            }
          }
        },
        path: "$jason.head.actions.$load"
        ...
      }]
      */

      var json = obj;
      try{ if (serialized) json = JSON.parse(obj); }
      catch (error) { }


      SELECT.$val = json;
      SELECT.$selected_root = json;

      if(filter) {
        SELECT.$selected = [];
        SELECT.exec(SELECT.$selected_root, '', filter);
      } else {
        SELECT.$selected = null;//{object: SELECT.$selected_root};
      }

      return SELECT;
    },
    transformWith: function(obj, serialized){
      SELECT.$parsed = [];
      /*
      'selected' is an array that contains items that looks like this:

      {
        key: The selected key,
        path: The path leading down to the selected key,
        object: The entire object that contains the currently selected key/val pair
        value: The selected value
      }
      */
      var template = obj;
      try{ if (serialized) template = JSON.parse(obj); }
      catch (error) { }

      // Setting $root
      SELECT.$template_root = template;
      String.prototype.$root = SELECT.$template_root;
      Array.prototype.$root = SELECT.$template_root;
      root = SELECT.$template_root;

      // generate new $selected_root
      if(SELECT.$selected && SELECT.$selected.length > 0) {
        SELECT.$selected.sort(function(a, b){
          // sort by path length, so that deeper level items will be replaced first
          // TODO: may need to look into edge cases
          return b.path.length - a.path.length;
        }).forEach(function(selection){
        //SELECT.$selected.forEach(function(selection) {
          // parse selected
          var parsed_object = TRANSFORM.run(template, selection.object);

          // apply the result to root
          SELECT.$selected_root = Helper.resolve(SELECT.$selected_root, selection.path, parsed_object);

          // update selected object with the parsed result
          selection.object = parsed_object
        });
        SELECT.$selected.sort(function(a,b) {
          return a.index - b.index;
        })
      } else {
        var parsed_object = TRANSFORM.run(template, SELECT.$selected_root);
        // apply the result to root
        SELECT.$selected_root = Helper.resolve(SELECT.$selected_root, "", parsed_object);

      }
      SELECT.$selected_root = JSON.parse(JSON.stringify(SELECT.$selected_root));
      return SELECT;
    },
    transform: function(obj, serialized){
      SELECT.$parsed = [];
      /*
      'selected' is an array that contains items that looks like this:

      {
        key: The selected key,
        path: The path leading down to the selected key,
        object: The entire object that contains the currently selected key/val pair
        value: The selected value
      }
      */
      var data = obj;
      try{ if (serialized) data = JSON.parse(obj); }
      catch (error) { }

      // since we're assuming that the template has been already selected, the $template_root is $selected_root
      SELECT.$template_root = SELECT.$selected_root;

      String.prototype.$root = data;
      Array.prototype.$root = data;
      root = data;

      if(SELECT.$selected && SELECT.$selected.length > 0) {
        SELECT.$selected.sort(function(a, b){
          // sort by path length, so that deeper level items will be replaced first
          // TODO: may need to look into edge cases
          return b.path.length - a.path.length;
        }).forEach(function(selection){
          // parse selected
          var parsed_object = TRANSFORM.run(selection.object, data);
          // apply the result to root
          SELECT.$template_root = Helper.resolve(SELECT.$template_root, selection.path, parsed_object);
          SELECT.$selected_root = SELECT.$template_root;

          // update selected object with the parsed result
          selection.object = parsed_object
        });
        SELECT.$selected.sort(function(a,b) {
          return a.index - b.index;
        })
      } else {
        var parsed_object = TRANSFORM.run(SELECT.$selected_root, data);
        // apply the result to root
        SELECT.$template_root = Helper.resolve(SELECT.$template_root, "", parsed_object);
        SELECT.$selected_root = SELECT.$template_root;
      }
      SELECT.$selected_root = JSON.parse(JSON.stringify(SELECT.$selected_root));
      return SELECT;
    },

    // Terminal methods
    objects: function(){
      if(SELECT.$selected) {
        return SELECT.$selected.map(function(item){ return item.object; })
      } else {
        return [SELECT.$selected_root];
      }
    },
    keys: function(){
      if(SELECT.$selected) {
        return SELECT.$selected.map(function(item){ return item.key; });
      } else {
        if(Array.isArray(SELECT.$selected_root)) {
          return Object.keys(SELECT.$selected_root).map(function(key) { return parseInt(key) });
        } else {
          return Object.keys(SELECT.$selected_root);
        }
      }
    },
    paths: function(){
      if(SELECT.$selected) {
        return SELECT.$selected.map(function(item){ return item.path; });
      } else {
        if(Array.isArray(SELECT.$selected_root)) {
          return Object.keys(SELECT.$selected_root).map(function(item) {
            // key is integer
            return "[" + item + "]";
          })
        } else {
          return Object.keys(SELECT.$selected_root).map(function(item) {
            // key is string
            return "[\"" + item + "\"]";
          })
        }
      }
    },
    values: function(){
      if(SELECT.$selected) {
        return SELECT.$selected.map(function(item){ return item.value; });
      } else {
        return Object.values(SELECT.$selected_root);
      }
    },
    root: function(){
      return SELECT.$selected_root;
    }
  };

  // Native JSON object override
  var _stringify = JSON.stringify;
  JSON.stringify = function(val, replacer, spaces){
    if(!replacer){
      return _stringify(val, function(key, val){
        if (key == "$root") { return undefined; }
        else { return val; }
      }, spaces);
    } else {
      return _stringify(val, replacer, spaces);
    }
  };
  JSON.select = SELECT.select;
  JSON.transform = TRANSFORM.transform;

  // Export
  if (typeof exports !== 'undefined') {
    var x = {
      TRANSFORM: TRANSFORM,
      SELECT: SELECT,
      Conditional: Conditional,
      Helper: Helper
    };
    if (typeof module !== 'undefined' && module.exports) { exports = module.exports = x; }
    exports = x;
  } else {
    $context["ST"] = {
      select: SELECT,
      transform: TRANSFORM
    }
  }
}(this));
