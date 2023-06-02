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

@_implementationOnly import MSAL_Private

protocol MSALNativeAuthSignInControlling: MSALNativeAuthTokenRequestHandling {

    func signIn(params: MSALNativeAuthSignInWithPasswordParameters, delegate: SignInPasswordStartDelegate)
    func signIn(params: MSALNativeAuthSignInWithCodeParameters, delegate: SignInCodeStartDelegate)
}

final class MSALNativeAuthSignInController: MSALNativeAuthBaseController, MSALNativeAuthSignInControlling {

    // MARK: - Variables

    private let requestProvider: MSALNativeAuthSignInRequestProviding
    private let factory: MSALNativeAuthResultBuildable
    private let responseValidator: MSALNativeAuthSignInResponseValidating

    // MARK: - Init

    init(
        clientId: String,
        requestProvider: MSALNativeAuthSignInRequestProviding,
        cacheAccessor: MSALNativeAuthCacheInterface,
        factory: MSALNativeAuthResultBuildable,
        responseValidator: MSALNativeAuthSignInResponseValidating
    ) {
        self.requestProvider = requestProvider
        self.factory = factory
        self.responseValidator = responseValidator
        super.init(
            clientId: clientId,
            cacheAccessor: cacheAccessor
        )
    }

    convenience init(config: MSALNativeAuthConfiguration) {
        self.init(
            clientId: config.clientId,
            requestProvider: MSALNativeAuthSignInRequestProvider(
                requestConfigurator: MSALNativeAuthRequestConfigurator(config: config)),
            cacheAccessor: MSALNativeAuthCacheAccessor(),
            factory: MSALNativeAuthResultFactory(config: config),
            responseValidator: MSALNativeAuthResponseValidator(responseHandler: MSALNativeAuthResponseHandler())
        )
    }

    func signIn(params: MSALNativeAuthSignInWithPasswordParameters, delegate: SignInPasswordStartDelegate) {
        let context = MSALNativeAuthRequestContext(correlationId: params.correlationId)
        MSALLogger.log(level: .verbose, context: context, format: "SignIn with email and password started")
        let scopes = joinScopes(params.scopes)
        let telemetryEvent = makeLocalTelemetryApiEvent(
            name: MSID_TELEMETRY_EVENT_API_EVENT,
            telemetryApiId: .telemetryApiIdSignInWithPassword,
            context: context
        )
        startTelemetryEvent(telemetryEvent, context: context)
        guard let request = createTokenRequest(
            username: params.username,
            password: params.password,
            scopes: scopes,
            context: context
        ) else {
            stopTelemetryEvent(telemetryEvent, context: context, error: MSALNativeAuthError.invalidRequest)
            DispatchQueue.main.async {
                delegate.onSignInPasswordError(error: SignInPasswordStartError(type: .generalError))
            }
            return
        }
        performRequest(request) { [self] aadTokenResponse in
            handleSignInTokenResult(
                aadTokenResponse,
                scopes: scopes,
                context: context,
                telemetryEvent: telemetryEvent,
                delegate: delegate)
        }
    }

    func signIn(params: MSALNativeAuthSignInWithCodeParameters, delegate: SignInCodeStartDelegate) {
        // call here /initiate
    }

    // MARK: - Private

    private func handleSignInTokenResult(
        _ aadTokenResponse: Result<MSIDAADTokenResponse, Error>,
        scopes: [String],
        context: MSALNativeAuthRequestContext,
        telemetryEvent: MSIDTelemetryAPIEvent?,
        delegate: SignInPasswordStartDelegate) {
        let config = factory.makeMSIDConfiguration(scope: scopes)
        let result = responseValidator.validateSignInTokenResponse(
            context: context,
            msidConfiguration: config,
            result: aadTokenResponse
        )
        switch result {
        case .success(let validatedTokenResult, let tokenResponse):
            telemetryEvent?.setUserInformation(validatedTokenResult.account)
            cacheTokenResponse(tokenResponse, context: context, msidConfiguration: config)
            let account = factory.makeUserAccount(tokenResult: validatedTokenResult)
            stopTelemetryEvent(telemetryEvent, context: context)
            MSALLogger.log(
                level: .verbose,
                context: context,
                format: "SignIn with email and password completed successfully")
            DispatchQueue.main.async {
                delegate.onSignInCompleted(result: account)
            }
        case .credentialRequired(let credentialToken):
            let challengeRequest = createChallengeRequest(
                credentialToken: credentialToken,
                context: context)
            print("credential required")
            // use the credential token to call /challenge API
            // create the new state and return it to the delegate
        case .error(let errorType):
            MSALLogger.log(
                level: .verbose,
                context: context,
                format: "SignIn with email and password completed with errorType: \(errorType)")
            stopTelemetryEvent(telemetryEvent, context: context, error: errorType)
            DispatchQueue.main.async {
                delegate.onSignInPasswordError(error: errorType.convertToSignInPasswordStartError())
            }
        }
    }

    private func createTokenRequest(username: String,
                                    password: String?,
                                    scopes: [String],
                                    context: MSIDRequestContext) -> MSIDHttpRequest? {
        do {
            let params = MSALNativeAuthSignInTokenRequestParameters(
                context: context,
                username: username,
                credentialToken: nil,
                signInSLT: nil,
                grantType: .password,
                scope: scopes.joined(separator: ","),
                password: password,
                oobCode: nil)
            return try requestProvider.token(parameters: params, context: context)
        } catch {
            MSALLogger.log(level: .error, context: context, format: "Error creating SignIn Token Request: \(error)")
            return nil
        }
    }

    private func createChallengeRequest(
        credentialToken: String,
        context: MSIDRequestContext
    ) -> MSIDHttpRequest? {
        do {
            let params = MSALNativeAuthSignInChallengeRequestParameters(
                context: context,
                credentialToken: credentialToken
            )
            return try requestProvider.challenge(parameters: params, context: context)
        } catch {
            MSALLogger.log(level: .error, context: context, format: "Error creating SignIn Token Request: \(error)")
            return nil
        }
    }

    private func joinScopes(_ scopes: [String]?) -> [String] {
        let defaultOIDCScopes = MSALPublicClientApplication.defaultOIDCScopes().array
        guard let scopes = scopes else {
            return defaultOIDCScopes as? [String] ?? []
        }
        let joinedScopes = NSMutableOrderedSet(array: scopes)
        joinedScopes.addObjects(from: defaultOIDCScopes)
        return joinedScopes.array as? [String] ?? []
    }
}
