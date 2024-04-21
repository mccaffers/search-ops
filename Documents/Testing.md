Erase all simulators, and boot iPhone 15

```
xcrun simctl erase all
xcrun simctl boot "iPhone 15"

xcodebuild \
-scheme SearchOpsTests \
-destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
-resultBundlePath TestResult/ \
-enableCodeCoverage YES \
-derivedDataPath "${RUNNER_TEMP}/Build/DerivedData" \
clean build test \
CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO 
```
