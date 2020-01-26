//
//  MSALDeviceInfoProviderTests.m
//  MSAL iOS Unit Tests
//
//  Created by Olga Dalton on 1/25/20.
//  Copyright © 2020 Microsoft. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MSALDeviceInfoProvider.h"
#import "MSIDTestSwizzle.h"
#import "MSIDSSOExtensionGetDeviceInfoRequest.h"
#import "MSIDTestParametersProvider.h"
#import "MSIDDeviceInfo.h"
#import "MSIDInteractiveTokenRequestParameters.h"
#import "MSALDeviceInformation.h"

@interface MSALDeviceInfoProviderTests : XCTestCase

@end

@implementation MSALDeviceInfoProviderTests

#pragma mark - Get device info

- (void)testGetDeviceInfo_whenCurrentSSOExtensionRequestAlreadyPresent_shouldReturnNilAndFillError API_AVAILABLE(ios(13.0), macos(10.15))
{
    [MSIDTestSwizzle classMethod:@selector(canPerformRequest)
                           class:[MSIDSSOExtensionGetDeviceInfoRequest class]
                           block:(id)^(id obj)
    {
        return YES;
    }];
    
    MSALDeviceInfoProvider *deviceInfoProvider = [MSALDeviceInfoProvider new];
    
    __block dispatch_semaphore_t dsem = dispatch_semaphore_create(0);
    
    [MSIDTestSwizzle instanceMethod:@selector(executeRequestWithCompletion:)
                              class:[MSIDSSOExtensionGetDeviceInfoRequest  class]
                              block:(id)^(id obj, MSIDGetDeviceInfoRequestCompletionBlock callback)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_semaphore_wait(dsem, DISPATCH_TIME_FOREVER);
            callback(nil, nil);
        });
    }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Get device info"];
    XCTestExpectation *failExpectation = [self expectationWithDescription:@"Failed expectation"];
    
    MSIDRequestParameters *requestParams = [MSIDTestParametersProvider testInteractiveParameters];
    requestParams.validateAuthority = YES;
    
    [deviceInfoProvider deviceInfoWithRequestParameters:requestParams
                                        completionBlock:^(MSALDeviceInformation * _Nullable deviceInformation, NSError * _Nullable error)
    {
        [expectation fulfill];
    }];
    
    [deviceInfoProvider deviceInfoWithRequestParameters:requestParams
                                        completionBlock:^(MSALDeviceInformation * _Nullable deviceInformation, NSError * _Nullable error)
    {
        XCTAssertNil(deviceInformation);
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, MSIDErrorDomain);
        XCTAssertEqual(error.code, MSIDErrorInternal);
        [failExpectation fulfill];
        dispatch_semaphore_signal(dsem);
    }];
    
    [self waitForExpectations:@[expectation, failExpectation] timeout:1];
}

- (void)testGetDeviceInfo_whenSSOExtensionNotAvailable_shouldReturnBrokerUnavailableError API_AVAILABLE(ios(13.0), macos(10.15))
{
    [MSIDTestSwizzle classMethod:@selector(canPerformRequest)
                           class:[MSIDSSOExtensionGetDeviceInfoRequest class]
                           block:(id)^(id obj)
    {
        return NO;
    }];
    
    MSALDeviceInfoProvider *deviceInfoProvider = [MSALDeviceInfoProvider new];
        
    XCTestExpectation *expectation = [self expectationWithDescription:@"Execute request"];
    expectation.inverted = YES;
    
    [MSIDTestSwizzle instanceMethod:@selector(executeRequestWithCompletion:)
                              class:[MSIDSSOExtensionGetDeviceInfoRequest  class]
                              block:(id)^(id obj, MSIDGetDeviceInfoRequestCompletionBlock callback)
    {
        [expectation fulfill];
    }];
    
    XCTestExpectation *failExpectation = [self expectationWithDescription:@"Get device info"];
    
    MSIDRequestParameters *requestParams = [MSIDTestParametersProvider testInteractiveParameters];
    requestParams.validateAuthority = YES;
    
    [deviceInfoProvider deviceInfoWithRequestParameters:requestParams
                                        completionBlock:^(MSALDeviceInformation * _Nullable deviceInformation, NSError * _Nullable error)
    {
        XCTAssertNil(deviceInformation);
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, MSIDErrorDomain);
        XCTAssertEqual(error.code, MSIDErrorBrokerNotAvailable);
        [failExpectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation, failExpectation] timeout:1];
}

- (void)testGetDeviceInfo_whenSSOExtensionPresent_encounteredError_shouldReturnError API_AVAILABLE(ios(13.0), macos(10.15))
{
    [MSIDTestSwizzle classMethod:@selector(canPerformRequest)
                           class:[MSIDSSOExtensionGetDeviceInfoRequest class]
                           block:(id)^(id obj)
    {
        return YES;
    }];
    
    MSALDeviceInfoProvider *deviceInfoProvider = [MSALDeviceInfoProvider new];
        
    XCTestExpectation *expectation = [self expectationWithDescription:@"Execute request"];
    
    [MSIDTestSwizzle instanceMethod:@selector(executeRequestWithCompletion:)
                              class:[MSIDSSOExtensionGetDeviceInfoRequest  class]
                              block:(id)^(id obj, MSIDGetDeviceInfoRequestCompletionBlock callback)
    {
        [expectation fulfill];
        NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorUnsupportedFunctionality, @"Unsupported functionality", nil, nil, nil, nil, nil, NO);
        callback(nil, error);
    }];
    
    XCTestExpectation *failExpectation = [self expectationWithDescription:@"Get device info"];
    
    MSIDRequestParameters *requestParams = [MSIDTestParametersProvider testInteractiveParameters];
    requestParams.validateAuthority = YES;
    
    [deviceInfoProvider deviceInfoWithRequestParameters:requestParams
                                        completionBlock:^(MSALDeviceInformation * _Nullable deviceInformation, NSError * _Nullable error)
    {
        XCTAssertNil(deviceInformation);
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, MSIDErrorDomain);
        XCTAssertEqual(error.code, MSIDErrorUnsupportedFunctionality);
        [failExpectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation, failExpectation] timeout:1];
}

- (void)testGetDeviceInfo_whenSSOExtensionPresent_andReturnedDeviceInfo_shouldReturnMSALDeviceInfo API_AVAILABLE(ios(13.0), macos(10.15))
{
    [MSIDTestSwizzle classMethod:@selector(canPerformRequest)
                           class:[MSIDSSOExtensionGetDeviceInfoRequest class]
                           block:(id)^(id obj)
    {
        return YES;
    }];
    
    MSALDeviceInfoProvider *deviceInfoProvider = [MSALDeviceInfoProvider new];
        
    XCTestExpectation *expectation = [self expectationWithDescription:@"Execute request"];
    
    [MSIDTestSwizzle instanceMethod:@selector(executeRequestWithCompletion:)
                              class:[MSIDSSOExtensionGetDeviceInfoRequest  class]
                              block:(id)^(id obj, MSIDGetDeviceInfoRequestCompletionBlock callback)
    {
        [expectation fulfill];
        
        MSIDDeviceInfo *deviceInfo = [MSIDDeviceInfo new];
        deviceInfo.brokerVersion = @"test";
        deviceInfo.deviceMode = MSIDDeviceModeShared;
        
        callback(deviceInfo, nil);
    }];
    
    XCTestExpectation *successExpectation = [self expectationWithDescription:@"Get device info"];
    
    MSIDRequestParameters *requestParams = [MSIDTestParametersProvider testInteractiveParameters];
    requestParams.validateAuthority = YES;
    
    [deviceInfoProvider deviceInfoWithRequestParameters:requestParams
                                        completionBlock:^(MSALDeviceInformation * _Nullable deviceInformation, NSError * _Nullable error)
    {
        XCTAssertNotNil(deviceInformation);
        XCTAssertNil(error);
        XCTAssertEqual(deviceInformation.deviceMode, MSALDeviceModeShared);
        [successExpectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation, successExpectation] timeout:1];
}

@end
