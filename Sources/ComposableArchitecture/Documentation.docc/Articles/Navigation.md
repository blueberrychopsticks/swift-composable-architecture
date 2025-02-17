# Navigation

Learn how to use the navigation tools in the library, including how to best model your domains, how
to integrate features in the reducer and view layers, and how to write tests.

## Overview

State-driven navigation is a powerful concept in application development, but can be tricky to 
master. The Composable Architecture provides the tools necessary to model your domains as concisely
as possible and drive navigation from state, but there are a few concepts to learn in order to best
use these tools.

## Topics

### Essentials
- <doc:WhatIsNavigation>

### Tree-based navigation

- <doc:TreeBasedNavigation>
- ``PresentationState``
- ``PresentationAction``
- ``ReducerProtocol/ifLet(_:action:destination:fileID:line:)``
- ``DismissEffect``

### Stack-based navigation

- <doc:StackBasedNavigation>
- ``StackState``
- ``StackAction``
- ``StackElementID``
- ``ReducerProtocol/forEach(_:action:destination:fileID:line:)``
- ``DismissEffect``
