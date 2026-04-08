#!/bin/bash
# Run this ONCE locally to generate a production keystore
# Save the output values in a secure place - you'll need them for GitHub secrets

KEYSTORE_PASSWORD="YourSecurePassword123"
KEY_ALIAS="your-alias"
KEY_PASSWORD="YourSecurePassword123"

echo "Generating RSA keystore..."
keytool -genkeypair \
  -v \
  -alias "$KEY_ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -sigalg SHA256withRSA \
  -validity 10000 \
  -keystore release-keystore.jks \
  -storepass "$KEYSTORE_PASSWORD" \
  -keypass "$KEY_PASSWORD" \
  -dname "CN=Morrow,O=Morrow,C=US"

echo ""
echo "Keystore created! Now encode to base64:"
echo "----------------------------------------"
base64 release-keystore.jks

echo ""
echo "Values to add to GitHub Secrets:"
echo "ANDROID_KEYSTORE_BASE64: <paste base64 output above>
ANDROID_KEYSTORE_PASSWORD: $KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS: $KEY_ALIAS
ANDROID_KEY_PASSWORD: $KEY_PASSWORD"
