# Hyperswitch iOS SDK

## Usage 

```ruby
pod 'hyperswitch-sdk-ios'
```

## Subspecs

```ruby
pod 'hyperswitch-sdk-ios/scancard'
pod 'hyperswitch-sdk-ios', :subspecs => ['subspec1', 'subspec2']
```

This repository hosts the essential components of the Hyperswitch SDK iOS, it is a submodule repo for [hyperswitch-client-core](https://github.com/juspay/hyperswitch-client-core), in order to complete the setup please clone hyperswitch-client-core and follow the instruction given in the README.

## Configuring Local Development Environment

The following table outlines the available configuration variables, their values, and descriptions:

| Key                 | Value         | Description                                      |
| :------------------ | :------------ | :----------------------------------------------- |
| `HyperswitchSource` | `LocalHosted` | Load the bundle from the Metro server            |
| `HyperswitchSource` | `LocalBundle` | Load the bundle from a pre-compiled local bundle |

`HyperswitchSource` defaults to `LocalHosted`.

### How to set variables

During local development, you may need to set specific variables to configure the SDK's behavior. You can set these variables using Xcode, command line interface (CLI), or any text editor.

### Xcode

Project > Targets > Info
Custom iOS Target Properties

### CLI

Alternatively, you can leverage the plutil command to modify the Info.plist file directly from the terminal. For example, to set the HyperswitchSource variable, execute the following command:

```shell
plutil -replace HyperswitchSource -string "LocalBundle" Info.plist
```

Info.plist is present in hyperswitch directory.

### Text Editor

If you prefer a more manual approach, you can open the Info.plist file in a text editor and add or modify the required keys and their corresponding values. For instance:

```
<key>HyperswitchSource</key>
<string>LocalHosted</string>
```

## Integration

Get started with our iOS [📚 integration guides](https://docs.hyperswitch.io/hyperswitch-cloud/integration-guide/ios)

## Licenses

- [Hyperswitch iOS SDK License](LICENSE)
