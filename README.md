# AvatarView (iOS / Flutter)

  

## Overview

  

`AvatarView` is a Flutter widget that displays a 3D avatar rendered **natively on iOS (Swift / SceneKit)**.

All avatar logic (model, animation, lip-sync) runs on the native side via **MethodChannels**.

  

Switching avatars is done by passing an `avatarName`. Everything else is resolved automatically.

  

---

  

## Usage

  

```dart

AvatarView(

avatarName: "Karl" or "Clara",

controller: _controller,

height: 400,

backgroundImagePath: "assets/images/background.png",

borderRadius: 0,

),
```

  

## Test Data

  

There is a test viseme file and matching audio under:

  

- `test/viseme.txt`

- `test/` (audio file)

  
  

## Current UI State

  

Some UI elements are already implemented.

  

- The **speaker icon** in the speech bubble currently triggers the **test playback** (audio + visemes).

  

## How It Works

  

- This behaves like a normal Flutter project, but avatar rendering is **iOS-only**

- The avatar system runs **natively in Swift**

- Flutter communicates with the native layer via **MethodChannels**

- Avatar model and animations are **separate files**