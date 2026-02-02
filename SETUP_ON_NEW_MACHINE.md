# Setup on New Machine

Quick guide to set up this project on another MacBook.

---

## Prerequisites

### 1. Install Xcode
```bash
# Download from Mac App Store or
xcode-select --install

# Set Xcode path
sudo xcode-select -s /Applications/Xcode.app
```

### 2. Install Homebrew (if not installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 3. Install Dependencies
```bash
# Protocol Buffer compiler
brew install protobuf

# Swift protobuf
brew install swift-protobuf

# Python 3 (usually pre-installed on macOS)
python3 --version
```

---

## Setup Steps

### 1. Clone Repository
```bash
cd ~/projects
git clone https://github.com/YOUR_USERNAME/meshTracker.git
cd meshTracker
```

### 2. Generate Swift Protobuf Files
```bash
# Navigate to protobuf directory
cd meshtastic-protobufs-full

# Generate Swift files
protoc --proto_path=. \
  --swift_out=../ios-bridge/MeshtasticGarminBridge/Protobufs \
  meshtastic/*.proto nanopb.proto

# Verify generation
ls ../ios-bridge/MeshtasticGarminBridge/Protobufs/meshtastic/
# Should see 23 .pb.swift files
```

### 3. Install Meshtastic CLI (Optional - for testing)
```bash
pip3 install meshtastic --user

# Add to PATH if needed
export PATH="$HOME/Library/Python/3.9/bin:$PATH"

# Verify installation
meshtastic --version
```

### 4. Open iOS Project in Xcode
```bash
open ios-bridge/MeshtasticGarminBridge.xcodeproj
```

In Xcode:
1. **Signing & Capabilities** tab
2. Select your **Team** (Apple Developer account)
3. Update **Bundle Identifier** if needed
4. Ensure **SwiftProtobuf** package dependency is resolved
   - File → Packages → Resolve Package Versions

### 5. Make Python Scripts Executable
```bash
cd ios-bridge/Scripts
chmod +x *.py
```

### 6. Test Setup
```bash
# If you have Meshtastic devices connected via USB
cd ios-bridge/Scripts
./test_mesh.py info

# Or just verify Python works
python3 test_mesh.py --help
```

---

## Garmin Connect IQ Setup (Optional)

### 1. Install Connect IQ SDK
Download from: https://developer.garmin.com/connect-iq/sdk/

Or install VS Code extension:
- Extension: "Monkey C" by Garmin

### 2. Build Garmin App
```bash
cd garmin-watchapp

# Using VS Code extension:
# Cmd+Shift+P → "Monkey C: Build for Device"

# Or command line (if SDK installed):
monkeyc \
  -o bin/Tracker.prg \
  -f monkey.jungle \
  -y ~/.Garmin/ConnectIQ/developer_key \
  -d instinct2x
```

---

## Verify Setup

### Quick Tests
```bash
# 1. Check dependencies
protoc --version        # Should show v33.x or higher
swift --version         # Should show Swift 5.x
python3 --version       # Should show Python 3.x

# 2. Verify protobuf files exist
ls ios-bridge/MeshtasticGarminBridge/Protobufs/meshtastic/ | wc -l
# Should show 23 or more files

# 3. Try building iOS app
cd ios-bridge
xcodebuild -project MeshtasticGarminBridge.xcodeproj \
  -scheme MeshtasticGarminBridge \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  clean build
```

---

## Troubleshooting

### "Command not found: protoc"
```bash
brew install protobuf
```

### "SwiftProtobuf package not resolved"
In Xcode:
- File → Packages → Reset Package Caches
- File → Packages → Resolve Package Versions

### "No such file: Protobufs/meshtastic/mesh.pb.swift"
Regenerate protobuf files:
```bash
cd meshtastic-protobufs-full
protoc --proto_path=. \
  --swift_out=../ios-bridge/MeshtasticGarminBridge/Protobufs \
  meshtastic/*.proto nanopb.proto
```

### "meshtastic: command not found"
```bash
pip3 install meshtastic --user
export PATH="$HOME/Library/Python/3.9/bin:$PATH"

# Add to ~/.zshrc or ~/.bash_profile for persistence
echo 'export PATH="$HOME/Library/Python/3.9/bin:$PATH"' >> ~/.zshrc
```

### Python version mismatch
Check your Python version:
```bash
python3 --version
# Adjust path in scripts if needed (default is Python 3.9)
```

---

## What's Included

After cloning, you should have:
- ✅ Complete iOS Bridge app source code
- ✅ Complete Garmin Watch app source code
- ✅ Python testing utilities
- ✅ Comprehensive documentation
- ✅ Xcode project configured
- ✅ Protobuf definitions (meshtastic-protobufs-full/)

**Note:** Protobuf Swift files are **generated**, not committed to git. You must run `protoc` to generate them on the new machine.

---

## Next Steps

1. Read **START_HERE.md** for project overview
2. Read **DEPLOYMENT_GUIDE.md** for deployment instructions
3. Connect Meshtastic devices and test
4. Build and deploy apps

---

**Need Help?**
- See QUICK_REFERENCE.md for common commands
- See DEPLOYMENT_GUIDE.md → Troubleshooting section
- Check PROJECT_STATUS.md for current status
