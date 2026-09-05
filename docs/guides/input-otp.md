# InputOtp (P3)

Use one bound string for an OTP; the control renders privacy-safe segments:

```swift
let otp = InputOtp("Verification code", value: otpBinding, length: 6)
otp.paste("123456")
otp.backspace()
```

The logical value is bounded and filtered to decimal digits by `OTPDocument`. Full paste, autofill, and backspace share the same document boundary. AX exposes a single text-field role without the secret value, and Prism never logs OTP contents.

## Extending

Hosts may provide secure text entry, IME/autofill integration, and localized announcements. Keep the value in an app-owned binding and avoid adding it to diagnostics or analytics.

## Limitations

The default document accepts decimal digits only. Resend timers, server verification, transport, and platform-native autofill configuration are outside this API.
