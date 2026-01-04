#!/bin/bash
# connect.sh - Connects to DC01 (default) or Client01

# 1. Determine which server to connect to
#    Usage: ./connect.sh        -> Connects to DC
#    Usage: ./connect.sh client -> Connects to Client
TARGET=${1:-dc}

if [[ "$TARGET" == "client" ]]; then
    SERVER_TAG="Client01-Member"
    DISPLAY_NAME="Member Server (Client01)"
else
    SERVER_TAG="DC01-Identity"
    DISPLAY_NAME="Domain Controller (DC01)"
fi

# 2. Find the Instance ID using the tag
echo "🔍 Finding $DISPLAY_NAME..."
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$SERVER_TAG" "Name=instance-state-name,Values=running" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text)

# 3. Handle Errors (Not found / Not running)
if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
    echo "❌ Error: Could not find running instance '$SERVER_TAG'."
    echo "   - If you just deployed, wait 2-3 minutes for initialization."
    echo "   - Ensure you are in the correct AWS Region."
    exit 1
fi

# 4. Connect via SSM
echo "✅ Found $INSTANCE_ID. Connecting..."
echo "------------------------------------------------------------------"
echo "💡 Tip: Type 'exit' to close the session."
echo "------------------------------------------------------------------"

aws ssm start-session --target $INSTANCE_ID