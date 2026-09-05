# ADR 0034: OTP Single Document and Privacy

`OTPDocument` owns one canonical, bounded string and exposes derived visual segments. `InputOtp` renders bullets and deliberately omits the value from accessibility/custom properties to avoid accidental disclosure; the host may provide a localized AX label such as “verification code”. Paste/autofill and backspace mutate the same document boundary.

OTP values are never logged by Prism. Platform autofill and secure text adapters remain host-owned. Reversal is additive: consumers can replace the facade while retaining the pure document contract.
