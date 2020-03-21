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

The resulting library (`postgresql-12.2/libpq.a`) will run natively on iOS 13.2, and there is some commented, and untested, code for the simulator as well.
