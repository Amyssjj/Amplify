# Network Security Configuration

## Info.plist Network Configuration

Add the following to your app's `Info.plist` to allow network communication:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <!-- Development localhost access -->
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
        <!-- Production API domain -->
        <key>api.amplify.app</key>
        <dict>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
        </dict>
    </dict>
</dict>
```

## Network Permissions

The app requires the following network permissions:

1. **Internet Access**: For API communication
2. **HTTP/HTTPS**: For REST API calls
3. **JSON**: For data exchange

## Security Features

- All authentication tokens stored in Keychain
- HTTPS enforced for production
- JWT-based authentication
- Automatic token refresh
- Secure network error handling

## Development vs Production

### Development
- Allows HTTP localhost connections
- Enhanced debug logging
- Mock API responses available

### Production  
- HTTPS only
- Minimal logging
- Live API endpoints
- Enhanced security headers