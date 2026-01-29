# GitHub Actions Workflows

This directory contains GitHub Actions workflows for the IConnect project.

## build-and-sign-dmg.yml

This workflow builds, signs (if certificates are provided), and packages the IConnect macOS application into a DMG file.

### Features

- **Automated Building**: Builds the Xcode project using the latest stable Xcode
- **Code Signing**: Supports optional code signing with certificates
- **DMG Creation**: Creates a professional DMG with proper layout and attribution
- **Release Integration**: Can create GitHub releases with the built DMG
- **Artifact Upload**: Uploads DMG as a GitHub Actions artifact

### Triggers

The workflow runs on:
- Git tags starting with 'v' (e.g., v1.0.0)
- Published releases
- Manual workflow dispatch

### Setup Instructions

#### Required Secrets (for signed builds)

To enable code signing, add these secrets to your GitHub repository:

1. **BUILD_CERTIFICATE_BASE64**: Base64-encoded Developer ID Application certificate (.p12 file)
   ```bash
   base64 -i YourCertificate.p12 | pbcopy
   ```

2. **P12_PASSWORD**: Password for the .p12 certificate file

3. **BUILD_PROVISION_PROFILE_BASE64**: Base64-encoded provisioning profile (optional for Developer ID)
   ```bash
   base64 -i YourProvisioningProfile.mobileprovision | pbcopy
   ```

#### Setting up Certificates

1. Export your Developer ID Application certificate from Keychain Access as a .p12 file
2. Convert to base64 and add as `BUILD_CERTIFICATE_BASE64` secret
3. Add the certificate password as `P12_PASSWORD` secret

#### Unsigned Builds

If you don't have code signing certificates, the workflow will automatically create an unsigned development build. These builds can still be used but may require users to manually allow them in System Preferences.

## Notes

Some workflows may reference the original upstream project in comments for historical context; the app built and packaged by these workflows is IConnect.