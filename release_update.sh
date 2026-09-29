#!/bin/bash
set -e

# Extract versions from Xcode project automatically
VERSION=$(grep -m1 'MARKETING_VERSION' BarJot.xcodeproj/project.pbxproj | awk -F'=' '{print $2}' | tr -d ' ;')
BUILD=$(grep -m1 'CURRENT_PROJECT_VERSION' BarJot.xcodeproj/project.pbxproj | awk -F'=' '{print $2}' | tr -d ' ;')

NOTES=${1:-"Updated BarJot to version $VERSION."}

echo "🚀 Building BarJot version $VERSION (build $BUILD)..."
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project BarJot.xcodeproj -scheme BarJot -configuration Release clean build -derivedDataPath build_output CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=YES CODE_SIGNING_ALLOWED=YES > /dev/null

echo "📦 Packaging DMG..."
rm -rf build_dmg "BarJot-$VERSION.dmg"
mkdir -p build_dmg/Applications
cp -R build_output/Build/Products/Release/BarJot.app build_dmg/
ln -s /Applications build_dmg/Applications
hdiutil create -volname "BarJot" -srcfolder build_dmg -ov -format UDZO "BarJot-$VERSION.dmg" > /dev/null

echo "🔑 Signing with Sparkle (You may be prompted for Keychain access)..."
SPARKLE_BIN="build_output/SourcePackages/artifacts/sparkle/Sparkle/bin"
# Fallback if SPARKLE_BIN is not there
if [ ! -f "$SPARKLE_BIN/sign_update" ]; then
    SPARKLE_BIN="build_output/SourcePackages/checkouts/Sparkle/bin"
fi
if [ ! -f "$SPARKLE_BIN/sign_update" ]; then
    # Try finding it
    SPARKLE_BIN=$(dirname "$(find build_output -name sign_update | head -n 1)")
fi

SIGNATURE=$("$SPARKLE_BIN/sign_update" "BarJot-$VERSION.dmg")

echo "📝 Updating docs/appcast.xml..."
DATE=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")
cat <<XML > docs/appcast.xml
<?xml version="1.0" standalone="yes"?>
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
    <channel>
        <title>BarJot Changelog</title>
        <link>https://moltas-su.github.io/BarJot/appcast.xml</link>
        <description>Most recent changes with links to updates.</description>
        <language>en</language>
        <item>
            <title>Version $VERSION</title>
            <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
            <sparkle:version>$BUILD</sparkle:version>
            <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
            <pubDate>$DATE</pubDate>
            <enclosure url="https://github.com/moltas-su/BarJot/releases/download/v$VERSION/BarJot-$VERSION.dmg"
                       sparkle:version="$BUILD"
                       sparkle:shortVersionString="$VERSION"
                       $SIGNATURE
                       type="application/octet-stream" />
        </item>
    </channel>
</rss>
XML

echo "☁️ Committing and pushing to GitHub..."
git add QuickNotepad/AppState.swift QuickNotepad/SettingsView.swift QuickNotepad/QuickNotepadApp.swift BarJot.xcodeproj/project.pbxproj docs/appcast.xml release_update.sh
git commit -m "Bump version to $VERSION, update appcast"
git push origin main

echo "🏷 Creating GitHub Release..."
gh release create "v$VERSION" "BarJot-$VERSION.dmg" --title "BarJot $VERSION" --notes "$NOTES"

echo "✅ All done! Sparkle updates should now work."
