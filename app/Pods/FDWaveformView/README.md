# FDWaveformView

[![CI Status](http://img.shields.io/travis/William Entriken/FDWaveformView.svg?style=flat)](https://travis-ci.org/fulldecent/FDWaveformView)
[![Version](https://img.shields.io/cocoapods/v/FDWaveformView.svg?style=flat)](http://cocoadocs.org/docsets/FDWaveformView)
[![License](https://img.shields.io/cocoapods/l/FDWaveformView.svg?style=flat)](http://cocoadocs.org/docsets/FDWaveformView)
[![Platform](https://img.shields.io/cocoapods/p/FDWaveformView.svg?style=flat)](http://cocoadocs.org/docsets/FDWaveformView)


FDWaveformView is an easy way to display an audio waveform in your app. It is a nice visualization to show a playing audio file or to select a position in a file.

Usage
-----

To use it, add an `FDWaveformView` using Interface Builder or programmatically and then just load your audio as per this example. Note: if your audio file does not have file extension, see <a href="https://stackoverflow.com/questions/9290972/is-it-possible-to-make-avurlasset-work-without-a-file-extension">this SO question</a>.

NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
NSString *filePath = [thisBundle pathForResource:@"Submarine" ofType:@"aiff"];
NSURL *url = [NSURL fileURLWithPath:filePath];
self.waveform.audioURL = url;

<p align="center">
<img src="https://i.imgur.com/5N7ozog.png" width=250>
</p>

Features
--------

**Set play progress** to highlight part of the waveform:

self.waveform.progressSamples = self.waveform.totalSamples / 2;

<p align="center">
<img src="https://i.imgur.com/fRrHiRP.png" width=250>
</p>

**Zoom in** to show only part of the waveform, of course, zooming in will smoothly rerender to show progressively more detail:

self.waveform.zoomStartSamples = 0;
self.waveform.zoomEndSamples = self.waveform.totalSamples / 4;

<p align="center">
<img src="https://i.imgur.com/JQOKQ3o.png" width=250>
</p>

**Enable gestures** for zooming in, panning around or scrubbing:

    self.waveform.doesAllowScrubbing = YES;
    self.waveform.doesAllowStretch = YES;
    self.waveform.doesAllowScroll = YES;

<p align="center">
<img src="https://i.imgur.com/8oR7cpq.gif" width=250 loop=infinite>
</p>

**Supports animation** for changing properties:

[UIView animateWithDuration:0.3 animations:^{
NSInteger randomNumber = arc4random() % self.waveform.totalSamples;
self.waveform.progressSamples = randomNumber;
}];

<p align="center">
<img src="https://i.imgur.com/EgxXaCY.gif" width=250 loop=infinite>
</p>


Creates **antialiased waveforms** by drawing more pixels than are seen on screen. Also, if you resize me (autolayout) I will render more detail if necessary to avoid pixelation.

**Supports ARC** and **iOS7+**.

**Includes unit tests** which run successfully using Travis CI.

Installation
------------

1. Add `pod 'FDWaveformView'` to your <a href="https://github.com/AFNetworking/AFNetworking/wiki/Getting-Started-with-AFNetworking">Podfile</a>
2. The the API documentation under "Class Reference" at http://cocoadocs.org/docsets/FDWaveformView/
3. Please add your project to "I USE THIS" at https://www.cocoacontrols.com/controls/fdwaveformview if you support this project
