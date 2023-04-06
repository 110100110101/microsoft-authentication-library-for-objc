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
public protocol SignInStartDelegate {
    /// This method is called when the signIn flow is interrupted.
    /// In this case the user needs to take action before to restart the signIn process.
    /// Checks the `reason` parameter to see more detail
    ///
    ///
    /// - Parameters:
    ///     - reason: The reason why the signIn flow got interrupted.
    ///
    func signInFlowInterrupted(reason: SignInStartFlowInterruptionReason)
    /// An error happened, but the user can continue the authentication flow.
    ///
    /// Checks the `error` parameter to see more detail
    ///
    ///
    /// - Parameters:
    ///     - error: Error details.
    ///
    func onError(error: SignInStartError)
    func onCodeSent(state: SignInCodeSentState, displayName: String, codeLength: Int)
    func completed(result: MSALNativeAuthUserAccount)
}

@objc
public protocol ResendCodeSignInDelegate {
    func onError(error: ResendCodeError)
    func onCodeSent(state: SignInCodeSentState, displayName: String, codeLength: Int)
}

@objc
public protocol VerifyCodeSignInDelegate {
    func verifyCodeFlowInterrupted(reason: BaseFlowInterruptionReason)
    func onError(error: VerifyCodeError, state: SignInCodeSentState)
    func completed(result: MSALNativeAuthUserAccount)
}
