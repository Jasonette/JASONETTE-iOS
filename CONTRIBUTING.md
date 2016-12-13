# How to contribute to Jasonette

## **Want to help with documentation?**

If you would like to contribute to the [documentation](https://jasonette.github.io/documentation/), let's discuss on the [documentation repository](https://github.com/Jasonette/documentation/issues).

## **Do you have a bug report or a feature request?**

* **Ensure the bug was not already reported** by searching on GitHub under [Issues](https://github.com/Jasonette/JASONETTE-iOS/issues).

* If you're unable to find an open issue addressing the problem, [open a new one](https://github.com/Jasonette/JASONETTE-iOS/issues/new). Be sure to include a **title and clear description**, as much relevant information as possible, and a **code sample** or an **executable test case** demonstrating the expected behavior that is not occurring.


## **Did you write a patch that fixes a bug?**

* Open a new GitHub pull request with the patch.

* Don't fork `master` branch. **Fork `develop` branch and send a pull request to `develop`.

* Ensure the PR description clearly describes the problem and solution. Include the relevant issue number if applicable.

## **Did you write a cool extension?**

Feel free to fork the project and [write your own extension](https://jasonette.github.io/documentation/advanced)

If you wrote a cool extension, please share it with the community in the [slack channel](https://jasonette.now.sh).

## **Do you have other types of questions?**

* Ask any question about how to use Jasonette on the [Jasonette Slack channel](https://jasonette.now.sh).

## **Project Structure**

### Class hierarchy
![hierarchy](https://raw.githubusercontent.com/gliechtenstein/images/master/hierarchy.png)

Here's a brief walkthrough of how the project is structured:

  - **Launcher**: You can ignore this, just some files that launches the app.
  - **Config**: Normally these are the only files you will ever need to touch.
    - `Info.plist`: App setting. Normally don't need to touch this unless you're manually setting up stuff.
    - `settings.plist`: **This is the only file you will ever need to change.** Set the `url` attribute to embed that URL into the app.
  - **Core**: Core logic that handles command processing (via stack, memory, etc.), view construction, templating, and some native system actions.
    - `Jason`: The brain of Jasonette. Everything revolves around this class. Makes use of JasonStack and JasonMemory for remembering and executing actions.
    - `JasonStack`: Stack for remembering instructions (actions).
    - `JasonMemory`: Used to store actions to be executed, through stack (JasonStack) and register.
    - `JasonParser`: Parser module that calls the `Core/Lib/parser.js` file for parsing json templates.
    - `RussianDollView`: A JasonViewController protocol, you can ignore this. 
    - **Assets**: You can ignore this, just some images and audio clips used by the app
    - **Lib**: Includes Javascript libraries used to execute JSON native actions.
      - `parser.js`: The main JSON parser that takes a JSON template expression and generates a final static JSON using the current register value
      - `csv.js`: CSV parser
      - `rss.js`: RSS parser
  - **Action**: Where all [actions](https://jasonette.github.io/documentation/actions/) are implemented. The implementation follows [the convention described here](https://jasonette.github.io/documentation/advanced/#2-extend-actions).
    - To build your own action extension, you can create your own custom group here and implement your own classes.
  - **View**: All view related classes.
    - `JasonViewController`: The main JSON-powered view controller. Everything view-related revolves around this class.
    - **Layer**: Implements [layers](https://jasonette.github.io/documentation/document/#bodylayers)
    - **Section**: Implements [sections](https://jasonette.github.io/documentation/document/#bodysections)
    - **Layout**: Implements [vertical and horizontal layouts](https://jasonette.github.io/documentation/layout/) that can be used inside [sections](https://jasonette.github.io/documentation/document/#bodysections)
    - **Component**: Implements [components](https://jasonette.github.io/documentation/components/), following [the convention described here](https://jasonette.github.io/documentation/advanced/#1-extend-ui-components).
      - To build your own component extension, just create your own group here and write your classes.
  - **Helper**
    - Various helper class methods used across various classes.

### What files you will be touching

####User
In most cases, the only thing you will ever need to touch is the `Config/settings.plist` file. This is where you set the main url your app will launch from.
  - But even this can be automatically done using the [Setup command](https://jasonette.github.io/documentation/#step-2-setup), which means **you will never need to touch anything inside XCode** to build an app.

####Advanced
Sometimes you may want to write an [extension](https://jasonette.github.io/documentation/advanced/#extension). In this case you may need to deal with:
  - `Action`: To write action extension
  - `View/Component`: To write UI component extension

####Guru
If you find a bug **anywhere in the code**, or have any improvements anywhere else, please feel free to:
  1. Fork the `develop` branch
  2. Create a feature branch
  3. Fix
  4. Send a pull request
