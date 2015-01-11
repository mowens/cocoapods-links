# cocoapods-links

A CocoaPods plugin to manage local development pods

## Installation

```bash
gem install cocoapods-links
```

## Purpose
Let's face it, pod development with local dependencies can be a pain. Let's say you have a project
`MyApp` a few pods declared in your `Podfile`:

```ruby
pod 'Foo', '~> 1.0.0'
pod 'Bar', :git => 'https://github.com/MyCompany/Bar.git', :tag => "1.0.1"
```

Perhaps you need to make some modifications to `Bar` to implement a new feature in `MyApp`. So
you modify your `Podfile`:

```ruby
pod 'Bar', :path => "/path/to/bar/checkout"
```
The problem with this you have to make a temporary change to your `Podfile`
that is managed by source control. Wouldn't it be great if CocoaPods offered a means to manage 
development pods without having to alter files under source control? 

Enter cocoapods-links.

Wtth cocoapods-links link functionality allows developers to easily test their pods.
Linking is a two-step process:

Using `pod link` in a project folder will register a global link. Then, in some other pod, 
`pod link <name>` will create a link to the registered pod as a Development pod.

This allows to easily test a pod because changes will be reflected immediately.
When the link is no longer necessary, simply remove it with `pod unlink <name>`.

## Usage

#### Register
To register a pod for local development linking:

```bash
pod link
```

#### Unregister
To unregister a pod:

```bash
pod unlink
```

#### Link
To link a pod for use in another pod project:

```bash
pod link <name>
```

#### Unlink
To unlink a pod from a pod project:

```bash
pod unlink <name>
```

#### List
To list all registered pods

```bash
pod list links
```

To list all linked pods in a pod project:

```bash
pod list links --linked
```

### License

cocoapods-links is released under the MIT license. See [LICENSE](LICENSE).
