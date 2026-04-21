# Android Signing Keystore

## Generate New Keystore
Run this command to create a new keystore:

```bash
keytool -genkeypair -v -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 \
  -keystore oasis-release.keystore \
  -alias oasis \
  -storepass OasisSecure123 \
  -keypass OasisSecure123 \
  -dname "CN=Oasis, O=Oasis, L=Delhi, S=Delhi, C=IN"
```

## Get Base64 for GitHub Secrets
```bash
# Linux/Mac
base64 oasis-release.keystore

# Windows (PowerShell)
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes("oasis-release.keystore"))
```

## Keystore Details
- **File**: oasis-release.keystore
- **Alias**: oasis
- **Store Password**: OasisSecure123
- **Key Password**: OasisSecure123
- **DN**: CN=Oasis, O=Oasis, L=Delhi, S=Delhi, C=IN
- **Validity**: 10,000 days (~27 years)
- **Algorithm**: RSA 2048-bit
- **Type**: PKCS12

## GitHub Secrets to Update
| Secret Name | Value |
|-------------|-------|
| KEYSTORE_BASE64 | (output of base64 command) |
| KEY_ALIAS | oasis |
| KEYSTORE_PASSWORD | OasisSecure123 |
| KEY_PASSWORD | OasisSecure123 |