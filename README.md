# libpq on iOS
A script to compile libpq for iOS 13.2

Instructions:
1. Clone:
```
git clone https://github.com/workflowproducts/libpq-ios
cd libpq-ios
```
2. Build:
```
./libpq-ios.sh
```

The resulting library (`postgresql-9.6.2/libpq.a`) will work run in the simulator, and all devices that support iOS 10.
At this time, the script is hard-coded to build for iOS 10.3, this requires a computer with macOS 10.12 Sierra and Xcode 8.3.
