//
// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import XCTest
@testable import MSAL
@_implementationOnly import MSAL_Private

final class MSALNativeAuthResetPasswordResponseValidatorTests: XCTestCase {

    private var sut: MSALNativeAuthResetPasswordResponseValidator!
    private var context: MSIDRequestContext!

    override func setUpWithError() throws {
        try super.setUpWithError()

        sut = MSALNativeAuthResetPasswordResponseValidator()
        context = MSALNativeAuthRequestContextMock()
    }

    // MARK: - Start Response

    func test_whenResetPasswordStartSuccessResponseContainsRedirect_it_returns_redirect() {
        let response: Result<MSALNativeAuthResetPasswordStartResponse, Error> = .success(
            .init(passwordResetToken: nil, challengeType: .redirect)
        )

        let result = sut.validate(response, with: context)
        XCTAssertEqual(result, .redirect)
    }

    func test_whenResetPasswordStartSuccessResponseDoesNotContainsTokenOrRedirect_it_returns_unexpectedError() {
        let response: Result<MSALNativeAuthResetPasswordStartResponse, Error> = .success(
            .init(passwordResetToken: nil, challengeType: .otp)
        )

        let result = sut.validate(response, with: context)
        XCTAssertEqual(result, .unexpectedError)
    }

    func test_whenResetPasswordStartSuccessResponseContainsToken_it_returns_success() {
        let response: Result<MSALNativeAuthResetPasswordStartResponse, Error> = .success(
            .init(passwordResetToken: "passwordResetToken", challengeType: .otp)
        )

        let result = sut.validate(response, with: context)

        guard case .success(let passwordResetToken) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(passwordResetToken, "passwordResetToken")
    }

    func test_whenResetPasswordStartErrorResponseIsNotExpected_it_returns_unexpectedError() {
        let response: Result<MSALNativeAuthResetPasswordStartResponse, Error> = .failure(NSError())

        let result = sut.validate(response, with: context)
        XCTAssertEqual(result, .unexpectedError)
    }

    func test_whenResetPasswordStartErrorResponseIsExpected_it_returns_error() {
        let error = MSALNativeAuthResetPasswordStartResponseError(error: .userNotFound)
        let response: Result<MSALNativeAuthResetPasswordStartResponse, Error> = .failure(error)

        let result = sut.validate(response, with: context)
        XCTAssertEqual(result, .error(.userNotFound))
    }

    // MARK: - Challenge Response

    func test_whenResetPasswordChallengeSuccessResponseContainsRedirect_it_returns_redirect() {
        let response: Result<MSALNativeAuthResetPasswordChallengeResponse, Error> = .success(.init(
            challengeType: .redirect,
            bindingMethod: nil,
            challengeTargetLabel: "challenge-type-label",
            challengeChannel: .email,
            passwordResetToken: "token",
            codeLength: nil)
        )

        let result = sut.validate(response, with: context)
        XCTAssertEqual(result, .redirect)
    }

    func test_whenResetPasswordChallengeSuccessResponseContainsValidAttributesAndOOB_it_returns_success() {
        let response: Result<MSALNativeAuthResetPasswordChallengeResponse, Error> = .success(.init(
            challengeType: .oob,
            bindingMethod: nil,
            challengeTargetLabel: "challenge-type-label",
            challengeChannel: .email,
            passwordResetToken: "token",
            codeLength: 6)
        )

        let result = sut.validate(response, with: context)

        guard case .success(let sentTo, let channelTargetType, let codeLength, let passwordResetToken) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(sentTo, "challenge-type-label")
        XCTAssertEqual(channelTargetType, .email)
        XCTAssertEqual(codeLength, 6)
        XCTAssertEqual(passwordResetToken, "token")
    }

    func test_whenResetPasswordChallengeSuccessResponseOmitsSomeAttributes_it_returns_unexpectedError() {
        let response: Result<MSALNativeAuthResetPasswordChallengeResponse, Error> = .success(.init(
            challengeType: .oob,
            bindingMethod: nil,
            challengeTargetLabel: "challenge-type-label",
            challengeChannel: .email,
            passwordResetToken: nil,
            codeLength: 6)
        )

        let result = sut.validate(response, with: context)
        XCTAssertEqual(result, .unexpectedError)
    }

    func test_whenResetPasswordChallengeSuccessResponseHasInvalidChallengeChannel_it_returns_unexpectedError() {
        let response: Result<MSALNativeAuthResetPasswordChallengeResponse, Error> = .success(.init(
            challengeType: .otp,
            bindingMethod: nil,
            challengeTargetLabel: "challenge-type-label",
            challengeChannel: .none,
            passwordResetToken: nil,
            codeLength: 6)
        )

        let result = sut.validate(response, with: context)
        XCTAssertEqual(result, .unexpectedError)
    }

    func test_whenResetPasswordChallengeErrorResponseIsNotExpected_it_returns_unexpectedError() {
        let response: Result<MSALNativeAuthResetPasswordChallengeResponse, Error> = .failure(NSError())

        let result = sut.validate(response, with: context)
        XCTAssertEqual(result, .unexpectedError)
    }

    func test_whenResetPasswordChallengeErrorResponseIsExpected_it_returns_error() {
        let error = MSALNativeAuthResetPasswordChallengeResponseError(error: .expiredToken)

        let response: Result<MSALNativeAuthResetPasswordChallengeResponse, Error> = .failure(error)

        let result = sut.validate(response, with: context)
        XCTAssertEqual(result, .error(.expiredToken))
    }

    // MARK: - Continue Response

    func test_whenResetPasswordContinueSuccessResponseContainsValidAttributesAndOOB_it_returns_success() {
        let response: Result<MSALNativeAuthResetPasswordContinueResponse, Error> = .success(.init(passwordSubmitToken: "passwordSubmitToken", expiresIn: 300))

        let result = sut.validate(response, with: context)

        guard case .success(let passwordSubmitToken) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(passwordSubmitToken, "passwordSubmitToken")
    }

    func test_whenResetPasswordContinueErrorResponseIsNotExpected_it_returns_unexpectedError() {
        let response: Result<MSALNativeAuthResetPasswordContinueResponse, Error> = .failure(NSError())

        let result = sut.validate(response, with: context)
        XCTAssertEqual(result, .unexpectedError)
    }

    func test_whenResetPasswordContinueErrorResponseIs_invalidOOBValue_it_returns_expectedError() {
        let result = buildContinueErrorResponse(expectedError: .invalidOOBValue)

        XCTAssertEqual(result, .invalidOOB)
    }

    func test_whenResetPasswordContinueErrorResponseIs_verificationRequired_it_returns_unexpectedError() {
        let result = buildContinueErrorResponse(expectedError: .verificationRequired)

        XCTAssertEqual(result, .unexpectedError)
    }

    func test_whenResetPasswordContinueErrorResponseIs_invalidClient_it_returns_expectedError() {
        let result = buildContinueErrorResponse(expectedError: .invalidClient)

        guard case .error(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .invalidClient)
    }

    func test_whenResetPasswordContinueErrorResponseIs_invalidGrant_it_returns_expectedError() {
        let result = buildContinueErrorResponse(expectedError: .invalidGrant)

        guard case .error(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .invalidGrant)
    }

    func test_whenResetPasswordContinueErrorResponseIs_expiredToken_it_returns_expectedError() {
        let result = buildContinueErrorResponse(expectedError: .expiredToken)

        guard case .error(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .expiredToken)
    }

    func test_whenResetPasswordContinueErrorResponseIs_invalidRequest_it_returns_expectedError() {
        let result = buildContinueErrorResponse(expectedError: .invalidRequest)

        guard case .error(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .invalidRequest)
    }

    // MARK: - Submit Response

    func test_whenResetPasswordSubmitSuccessResponseContainsToken_it_returns_success() {
        let response: Result<MSALNativeAuthResetPasswordSubmitResponse, Error> = .success(.init(passwordResetToken: "passwordResetToken", pollInterval: 1))

        let result = sut.validate(response, with: context)

        guard case .success(let passwordResetToken, let pollInterval) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(passwordResetToken, "passwordResetToken")
        XCTAssertEqual(pollInterval, 1)
    }

    func test_whenResetPasswordSubmitErrorResponseIs_passwordTooWeak_it_returns_expectedError() {
        let result = buildSubmitErrorResponse(expectedError: .passwordTooWeak)

        guard case .passwordError(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .passwordTooWeak)
    }

    func test_whenResetPasswordSubmitErrorResponseIs_passwordTooShort_it_returns_expectedError() {
        let result = buildSubmitErrorResponse(expectedError: .passwordTooShort)

        guard case .passwordError(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .passwordTooShort)
    }

    func test_whenResetPasswordSubmitErrorResponseIs_passwordTooLong_it_returns_expectedError() {
        let result = buildSubmitErrorResponse(expectedError: .passwordTooLong)

        guard case .passwordError(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .passwordTooLong)
    }

    func test_whenResetPasswordSubmitErrorResponseIs_passwordRecentlyUsed_it_returns_expectedError() {
        let result = buildSubmitErrorResponse(expectedError: .passwordRecentlyUsed)

        guard case .passwordError(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .passwordRecentlyUsed)
    }

    func test_whenResetPasswordSubmitErrorResponseIs_passwordBanned_it_returns_expectedError() {
        let result = buildSubmitErrorResponse(expectedError: .passwordBanned)

        guard case .passwordError(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .passwordBanned)
    }

    func test_whenResetPasswordSubmitErrorResponseIs_invalidRequest_it_returns_expectedError() {
        let result = buildSubmitErrorResponse(expectedError: .invalidRequest)

        guard case .error(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .invalidRequest)
    }

    func test_whenResetPasswordSubmitErrorResponseIs_invalidClient_it_returns_expectedError() {
        let result = buildSubmitErrorResponse(expectedError: .invalidClient)

        guard case .error(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .invalidClient)
    }

    func test_whenResetPasswordSubmitErrorResponseIs_expiredToken_it_returns_expectedError() {
        let result = buildSubmitErrorResponse(expectedError: .expiredToken)

        guard case .error(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .expiredToken)
    }

    func test_whenResetPasswordSubmitErrorResponseIsNotExpected_it_returns_unexpectedError() {
        let response: Result<MSALNativeAuthResetPasswordSubmitResponse, Error> = .failure(NSError())

        let result = sut.validate(response, with: context)
        XCTAssertEqual(result, .unexpectedError)
    }

    // MARK: - Poll Completion Response

    func test_whenResetPasswordPollCompletionSuccessResponse_it_returns_success() {
        let response: Result<MSALNativeAuthResetPasswordPollCompletionResponse, Error> = .success(.init(status: .succeeded, signInSLT: nil, expiresIn: nil))

        let result = sut.validate(response, with: context)

        guard case .success(let status) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(status, .succeeded)
    }

    func test_whenResetPasswordPollCompletionErrorResponseIs_passwordTooWeak_it_returns_expectedError() {
        let result = buildPollCompletionErrorResponse(expectedError: .passwordTooWeak)

        guard case .passwordError(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .passwordTooWeak)
    }

    func test_whenResetPasswordPollCompletionErrorResponseIs_passwordTooShort_it_returns_expectedError() {
        let result = buildPollCompletionErrorResponse(expectedError: .passwordTooShort)

        guard case .passwordError(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .passwordTooShort)
    }

    func test_whenResetPasswordPollCompletionErrorResponseIs_passwordTooLong_it_returns_expectedError() {
        let result = buildPollCompletionErrorResponse(expectedError: .passwordTooLong)

        guard case .passwordError(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .passwordTooLong)
    }

    func test_whenResetPasswordPollCompletionErrorResponseIs_passwordRecentlyUsed_it_returns_expectedError() {
        let result = buildPollCompletionErrorResponse(expectedError: .passwordRecentlyUsed)

        guard case .passwordError(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .passwordRecentlyUsed)
    }

    func test_whenResetPasswordPollCompletionErrorResponseIs_passwordBanned_it_returns_expectedError() {
        let result = buildPollCompletionErrorResponse(expectedError: .passwordBanned)

        guard case .passwordError(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .passwordBanned)
    }

    func test_whenResetPasswordPollCompletionErrorResponseIs_invalidRequest_it_returns_expectedError() {
        let result = buildPollCompletionErrorResponse(expectedError: .invalidRequest)

        guard case .error(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .invalidRequest)
    }

    func test_whenResetPasswordPollCompletionErrorResponseIs_invalidClient_it_returns_expectedError() {
        let result = buildPollCompletionErrorResponse(expectedError: .invalidClient)

        guard case .error(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .invalidClient)
    }

    func test_whenResetPasswordPollCompletionErrorResponseIs_expiredToken_it_returns_expectedError() {
        let result = buildPollCompletionErrorResponse(expectedError: .expiredToken)

        guard case .error(let error) = result else {
            return XCTFail("Unexpected response")
        }

        XCTAssertEqual(error, .expiredToken)
    }

    func test_whenResetPasswordPollCompletionErrorResponseIsNotExpected_it_returns_unexpectedError() {
        let response: Result<MSALNativeAuthResetPasswordPollCompletionResponse, Error> = .failure(NSError())

        let result = sut.validate(response, with: context)
        XCTAssertEqual(result, .unexpectedError)
    }

    // MARK: - Helper methods

    private func buildContinueErrorResponse(
        expectedError: MSALNativeAuthResetPasswordContinueOauth2ErrorCode,
        expectedPasswordResetToken: String? = nil
    ) -> MSALNativeAuthResetPasswordContinueValidatedResponse {
        let response: Result<MSALNativeAuthResetPasswordContinueResponse, Error> = .failure(
            MSALNativeAuthResetPasswordContinueResponseError(
                error: expectedError,
                passwordResetToken: expectedPasswordResetToken
            )
        )

        return sut.validate(response, with: context)
    }

    private func buildSubmitErrorResponse(
        expectedError: MSALNativeAuthResetPasswordSubmitOauth2ErrorCode
    ) -> MSALNativeAuthResetPasswordSubmitValidatedResponse {
        let response: Result<MSALNativeAuthResetPasswordSubmitResponse, Error> = .failure(
            MSALNativeAuthResetPasswordSubmitResponseError(
                error: expectedError
            )
        )

        return sut.validate(response, with: context)
    }

    private func buildPollCompletionErrorResponse(
        expectedError: MSALNativeAuthResetPasswordPollCompletionOauth2ErrorCode
    ) -> MSALNativeAuthResetPasswordPollCompletionValidatedResponse {
        let response: Result<MSALNativeAuthResetPasswordPollCompletionResponse, Error> = .failure(
            MSALNativeAuthResetPasswordPollCompletionResponseError(
                error: expectedError
            )
        )

        return sut.validate(response, with: context)
    }
}
