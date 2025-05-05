xcrun simctl list | grep "iPhone 16"
xcrun simctl boot "iPhone 16"
sleep 5;
rm -rf ./Build
rm -rf ./TestResult
xcodebuild \
        -scheme SearchOpsUnitTests \
        -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
        -resultBundlePath TestResult/ \
        -enableCodeCoverage YES \
        -derivedDataPath Build/DerivedData \
        clean build test \
        CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO 