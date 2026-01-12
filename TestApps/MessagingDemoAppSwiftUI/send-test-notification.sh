#!/bin/bash

# Script to send test push notifications to iOS Simulator with XDM tracking data
# Usage: ./send-test-notification.sh [notification-type]
#        notification-type: simple, deeplink, dismiss, fulltracking, or full (default: full)

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Default values
BUNDLE_ID="com.adobe.MessagingDemoApp"
NOTIFICATION_TYPE="${1:-full}"

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🚀 Push Notification Test Script with XDM Tracking${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Get booted simulator
echo -e "${YELLOW}📱 Finding booted simulator...${NC}"
SIMULATOR_ID=$(xcrun simctl list devices | grep "Booted" | head -1 | grep -o "[A-F0-9-]\{36\}")

if [ -z "$SIMULATOR_ID" ]; then
    echo -e "${RED}❌ Error: No booted simulator found${NC}"
    echo -e "${YELLOW}💡 Please start a simulator first using:${NC}"
    echo -e "   open -a Simulator"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Found booted simulator: ${SIMULATOR_ID}${NC}"
echo ""

# Select APNS file based on notification type
case "$NOTIFICATION_TYPE" in
    "simple")
        APNS_FILE="$SCRIPT_DIR/test-notification-simple.apns"
        DESCRIPTION="Simple test notification with minimal XDM data"
        ;;
    "deeplink")
        APNS_FILE="$SCRIPT_DIR/test-notification-with-deeplink.apns"
        DESCRIPTION="Notification with deeplink and full XDM tracking"
        ;;
    "dismiss")
        APNS_FILE="$SCRIPT_DIR/test-notification-with-dismiss.apns"
        DESCRIPTION="Notification with Accept & Dismiss buttons (TRACKABLE_CATEGORY)"
        ;;
    "fulltracking")
        APNS_FILE="$SCRIPT_DIR/test-notification-full-tracking.apns"
        DESCRIPTION="Notification with Accept, Decline & Dismiss buttons (FULL_TRACKING_CATEGORY)"
        ;;
    "full"|*)
        APNS_FILE="$SCRIPT_DIR/test-notification-with-xdm.apns"
        DESCRIPTION="Full test notification with complete XDM tracking data and action buttons"
        ;;
esac

# Check if APNS file exists
if [ ! -f "$APNS_FILE" ]; then
    echo -e "${RED}❌ Error: APNS file not found: $APNS_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}📦 Using notification file:${NC} $(basename "$APNS_FILE")"
echo -e "${YELLOW}📝 Description:${NC} $DESCRIPTION"
echo -e "${YELLOW}🎯 Bundle ID:${NC} $BUNDLE_ID"
echo ""

# Send the notification
echo -e "${BLUE}📤 Sending push notification to simulator...${NC}"
echo ""

xcrun simctl push "$SIMULATOR_ID" "$BUNDLE_ID" "$APNS_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ Notification sent successfully!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}📋 Next steps:${NC}"
    echo -e "   1. Check the notification on the simulator"
    echo -e "   2. Tap the notification to trigger the XDM tracking flow"
    echo -e "   3. Check Xcode console for tracking logs (Flow Steps 1-8)"
    echo ""
    echo -e "${YELLOW}🔍 Look for these logs:${NC}"
    echo -e "   • ${GREEN}[DEMO APP]${NC} - Notification reception logs"
    echo -e "   • ${GREEN}[FLOW STEP 2]${NC} - XDM tracking data found"
    echo -e "   • ${GREEN}[FLOW STEP 3-8]${NC} - Complete tracking flow"
    echo ""
    echo -e "${YELLOW}💡 Available notification types:${NC}"
    echo -e "   • ./send-test-notification.sh simple       - Minimal XDM"
    echo -e "   • ./send-test-notification.sh deeplink     - With deeplink"
    echo -e "   • ./send-test-notification.sh dismiss      - Accept & Dismiss buttons"
    echo -e "   • ./send-test-notification.sh fulltracking - Accept, Decline & Dismiss buttons"
    echo -e "   • ./send-test-notification.sh full         - Complete XDM + actions"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Failed to send notification${NC}"
    echo -e "${YELLOW}💡 Troubleshooting:${NC}"
    echo -e "   1. Make sure the simulator is booted"
    echo -e "   2. Verify the app is installed on the simulator"
    echo -e "   3. Check if the bundle ID is correct: $BUNDLE_ID"
    echo ""
    exit 1
fi

