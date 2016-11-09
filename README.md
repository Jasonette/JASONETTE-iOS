[![logo](https://raw.githubusercontent.com/gliechtenstein/images/master/jasonette.png)](http://www.jasonette.com)

# [Jasonette](https://www.jasonette.com)

[https://www.jasonette.com](https://www.jasonette.com)

Create your own native iOS app with nothing but JSON. Then send it over the Internet.

##★ Jasonette fetches this JSON markup from a server:

![json](https://raw.githubusercontent.com/gliechtenstein/images/master/json.png)

##★ And self-constructs into the following native app, in realtime:

![instagram](https://github.com/Jasonette/Instagram-UI-example/blob/master/images/instagram.gif)

<br>

#Cool things about Jasonette

- **100% NATIVE**: Jasonette maps JSON into native components and native function calls. There is no gimmick. There is no magic.
- **App loads over HTTP**: Your app exists 100% as JSON, and loads from the cloud. No more hard-coding.
- **An app in 30 minutes**: No kidding, build an app in 30 minutes.
- **Lowest possible learning curve**: No programming experience required. There's only one thing you need to know: JSON. Which means you can build an app without "becoming a programmer".

<br>

# [Quickstart](https://www.jasonette.com)
Visit [Getting started](https://jasonette.github.io/documentation/) guide.

<br>

# Download
Latest release: [ver0.1.0](https://jasonette.github.io/documentation)

<br>

# More Examples
Try playing these on Jasonette and watch them turn into native apps in front of your eyes!

* [Jasonpedia](https://github.com/Jasonette/Jasonpedia) Tutorial demo app that includes all Jasonette feature implementations.
* [Instagram](https://github.com/Jasonette/Instagram-UI-example) An Instagram UI, 100% powered by JSON.
* [Twitter](https://github.com/Jasonette/Twitter-UI-example) A Twitter UI, 100% powered by JSON.

<br>

# Technical Highlights

##1. One JSON to rule them all

Jasonette simplifies the entire app building process down to nothing more than:

1. Write a JSON markup
2. Add the JSON url to Jasonette
3. Press `play`

This is possible because Jasonette came up with a way to **fit an entire app worth of logic into a single declarative JSON that just works™.** This JSON grammar is used to express **every aspect of your app**, such as:

1. Draw sophisticated [**views**](https://jasonette.github.io/documentation/document)
2. Call [**device API methods**](https://jasonette.github.io/documentation/actions/#api)
3. Chain method calls to [**perform complex logic**](https://jasonette.github.io/documentation/actions/#b-handling-another-actions-result)
4. Respond to [**system events**](https://jasonette.github.io/documentation/actions/#system-events) and [**user interaction**](https://jasonette.github.io/documentation/actions/#a-handling-user-interaction)
5. Even change the JSON itself dynamically using [**templates**](https://jasonette.github.io/documentation/templates).

<br>

##2. App-over-HTTP
Until now, the only thing JSON could send over the Internet was raw data. Normally apps would fetch remote data from the server for a connected experience, but the actual app logic would be hard-coded on the client side. This makes it hard to update and extend apps.

But what happens when you can express an entire app logic as JSON?

**Then apps can be stored, processed, shared, and sent over the Internet just like any other JSON.** Watch below where we update the JSON on a [JSON pastebin server](https://www.jasonbase.com), and the app changes immediately to reflect the new markup:

![remote control](http://i.giphy.com/3o7TKrdmlX5uD7RszK.gif)

<br>

##3. Designed to be extended or integrated
Currently Jasonette covers all the essential native APIs and components, which means you can build pretty much any app you can imagine. But Jasonette is very flexible.

###A. Extensible
If you don't see a feature you want, you can simply [extend Jasonette](https://jasonette.github.io/documentation/advanced/#extension-vs-integration). If it's useful for the general public, we can even merge it into the core.

###B. Integrate existing code
You can even [integrate Jasonette with your existing iOS project](https://jasonette.github.io/documentation/advanced/#extension-vs-integration) if you want. This way you can use Jasonette for just a small part of your app without having to completely switch to a new way of programming.

<br>

# Bugs and feature requests

Have a bug or a feature request regarding the Jasonette code itself? [Please open a new issue](https://github.com/Jasonette/JASONETTE-iOS/issues/new).

<br>

# Questions and Support
For questions and support, please use the [Slack chatroom](https://jasonette.herokuapp.com)

[![slack](https://raw.githubusercontent.com/gliechtenstein/images/master/slack.png)](https://jasonette.herokuapp.com)

<br>

# Stay in touch
To keep updated on latest releases and announcements,

- Follow on Twitter [@jasonclient](https://twitter.com/jasonclient)
- [join our slack](https://jasonette.herokuapp.com)

<br>

# Contribute
There are many ways to contribute. But first, please [read the contributing guideline](CONTRIBUTING.md)

<br>

# License
Jasonette is released under the [MIT License](http://www.opensource.org/licenses/MIT).
