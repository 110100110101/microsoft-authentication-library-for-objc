#!/bin/bash
# To build manually run "sudo sh build_docs.sh"
gem install jazzy
echo -e "Copying MSAL public files"
mkdir docs.temp
mkdir docs.temp/MSAL
cp `find MSAL/src/public` docs.temp/MSAL
cp `find MSAL/src/native_auth/public` docs.temp/MSAL
cp README.md docs.temp/

echo -e "Generating MSAL documentation"
# Generate Swift SourceKitten output
sourcekitten doc -- -workspace MSAL.xcworkspace -scheme "MSAL (iOS Framework)" -configuration Debug RUN_CLANG_STATIC_ANALYZER=NO -sdk iphonesimulator CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -destination 'platform=iOS Simulator' > docs.temp/swiftDoc.json

# Generate Objective-C SourceKitten output
cd docs.temp
sourcekitten doc --objc $(pwd)/MSAL/MSAL.h -- -x objective-c  -isysroot $(xcrun --show-sdk-path --sdk iphonesimulator) \-I $(pwd) -fmodules > objcDoc.json
cd ..

# Feed both outputs to Jazzy as a comma-separated list
jazzy --module MSAL --sourcekitten-sourcefile docs.temp/swiftDoc.json,docs.temp/objcDoc.json --author Microsoft\ Corporation --author_url https://aka.ms/azuread --github_url https://github.com/AzureAD/microsoft-authentication-library-for-objc --theme fullwidth