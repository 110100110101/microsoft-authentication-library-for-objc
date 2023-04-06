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
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

@objc
public enum MSALNativeAuthChallengeType: Int {
    case oob
    case password
}

@objcMembers
public final class MSALNativeAuthPublicClientApplication: MSALPublicClientApplication {

    private let controllerFactory: MSALNativeAuthRequestControllerBuildable
    private let inputValidator: MSALNativeAuthInputValidating

    public override init(configuration config: MSALPublicClientApplicationConfig) throws {
        guard let aadAuthority = config.authority as? MSALAADAuthority else {
            throw MSALNativeAuthError.invalidAuthority
        }

        let nativeConfiguration = try MSALNativeAuthConfiguration(
            clientId: config.clientId,
            authority: aadAuthority
        )

        self.controllerFactory = MSALNativeAuthRequestControllerFactory(config: nativeConfiguration)
        self.inputValidator = MSALNativeAuthInputValidator()

        try super.init(configuration: config)
    }

    public init(
        clientId: String,
        challengeTypes: [MSALNativeAuthChallengeType],
        rawTenant: String? = nil,
        redirectUri: String? = nil) throws {
        let aadAuthority = try MSALNativeAuthAuthorityProvider()
            .authority(rawTenant: rawTenant)

        let nativeConfiguration = try MSALNativeAuthConfiguration(
            clientId: clientId,
            authority: aadAuthority,
            rawTenant: rawTenant
        )

        self.controllerFactory = MSALNativeAuthRequestControllerFactory(config: nativeConfiguration)
        self.inputValidator = MSALNativeAuthInputValidator()

        let configuration = MSALPublicClientApplicationConfig(
            clientId: clientId,
            redirectUri: redirectUri,
            authority: aadAuthority
        )

        try super.init(configuration: configuration)
    }

    init(
        controllerFactory: MSALNativeAuthRequestControllerBuildable,
        inputValidator: MSALNativeAuthInputValidating
    ) {
        self.controllerFactory = controllerFactory
        self.inputValidator = inputValidator

        super.init()
    }

    // MARK: delegate methods

    public func signUp(
        username: String,
        password: String?,
        attributes: [String: Any],
        correlationId: UUID? = nil,
        delegate: SignUpStartDelegate
    ) {
            switch username {
            case "exists@contoso.com": delegate.signUpFlowInterrupted(reason: .userAlreadyExists)
            case "redirect@contoso.com": delegate.signUpFlowInterrupted(reason: .redirect)
            case "invalidpassword@contoso.com": delegate.onError(error: SignUpStartError(type: .passwordInvalid))
            case "invalidattributes@contoso.com": delegate.onError(error: SignUpStartError(type: .invalidAttributes))
            case "generalerror@contoso.com": delegate.onError(error: SignUpStartError(type: .generalError))
            default: delegate.onCodeSent(
                state: SignUpCodeSentState(flowToken: "signup_token"),
                displayName: username,
                codeLength: 4)
            }
    }

    public func signIn(
        username: String,
        password: String?,
        correlationId: UUID? = nil,
        delegate: SignInStartDelegate
    ) {
        switch username {
        case "notfound@contoso.com": delegate.signInFlowInterrupted(reason: .userNotFound)
        case "redirect@contoso.com": delegate.signInFlowInterrupted(reason: .redirect)
        case "invalidauth@contoso.com": delegate.signInFlowInterrupted(reason: .invalidAuthenticationType)
        case "invalidpassword@contoso.com": delegate.onError(error: SignInStartError(type: .passwordInvalid))
        case "generalerror@contoso.com": delegate.onError(error: SignInStartError(type: .generalError))
        case "oob@contoso.com": delegate.onCodeSent(
            state: SignInCodeSentState(flowToken: "credential_token"),
            displayName: username,
            codeLength: 4)
        default: delegate.completed(
            result:
                MSALNativeAuthUserAccount(
                    username: username,
                    accessToken: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Imk2bEdrM0ZaenhSY1ViMkMzbkVRN3N5SEpsWSIsImtpZCI6Imk2bEdrM0ZaenhSY1ViMkMzbkVRN3N5SEpsWSJ9"))
        }
    }

    public func resetPassword(
        username: String,
        correlationId: UUID? = nil,
        delegate: ResetPasswordStartDelegate
    ) {
        switch username {
        case "redirect@contoso.com": delegate.resetPasswordFlowInterrupted(reason: .redirect)
        case "nopassword@contoso.com": delegate.resetPasswordFlowInterrupted(reason: .userDoesNotHavePassword)
        case "notfound@contoso.com": delegate.resetPasswordFlowInterrupted(reason: .userNotFound)
        case "generalerror@contoso.com": delegate.onError(error: ResetPasswordStartError(type: .generalError))
        default: delegate.onCodeSent(state:
                                        CodeSentResetPasswordState(flowToken: "password_reset_token"), displayName: username, codeLength: 4)
        }
    }

    public func getUserAccount() async throws -> MSALNativeAuthUserAccount {
        return MSALNativeAuthUserAccount(
            username: "email@contoso.com",
            accessToken: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Imk2bEdrM0ZaenhSY1ViMkMzbkVRN3N5SEpsWSIsImtpZCI6Imk2bEdrM0ZaenhSY1ViMkMzbkVRN3N5SEpsWSJ9"
        )
    }
}
