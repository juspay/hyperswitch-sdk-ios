# Hyperswitch iOS SDK

This repository hosts the essential components of the Hyperswitch SDK iOS, it is a submodule repo for [hyperswitch-client-core](https://github.com/juspay/hyperswitch-client-core), in order to complete the setup please clone hyperswitch-client-core and follow the instruction given in the README.

Environment Variables are set in Xcode under the Scheme Configurations. Arguments Tab allows us to add or remove a specific key value pair in UI. You can even enable or disable specific key value pair in a run.

Edit Scheme > Run > Arguments

| Key                     | Value                              | Description                                   |
| :---------------------- | :--------------------------------- | :-------------------------------------------- |
| `HYPERSWITCH_JS_SOURCE` | `LOCAL_HOSTED_FOR_SIMULATOR`       | load from metro server on iOS simulator       |
| `HYPERSWITCH_JS_SOURCE` | `LOCAL_HOSTED_FOR_PHYSICAL_DEVICE` | load from metro server on physical iOS device |
| `HYPERSWITCH_JS_SOURCE` | `LOCAL_BUNDLE`                     | load from local pre-compiled bundle           |
