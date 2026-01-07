# Firestore Rules Setup Guide

## Issue
Getting `PERMISSION_DENIED` error when creating events.

## Solution
Deploy your Firestore security rules to Firebase.

## Steps

### Option 1: Deploy via Firebase Console (Easiest)

1. Open your browser and go to:
   ```
   https://console.firebase.google.com/project/event-sphere-f3f91/firestore/rules
   ```

2. Click on the rules editor (you should see the current rules)

3. Open the file: `firestore.rules` in your project

4. Copy ALL the contents from `firestore.rules`

5. Paste into the Firebase Console rules editor

6. Click the **"Publish"** button at the top

7. Wait for confirmation that rules are deployed

### Option 2: Deploy via Firebase CLI

```bash
# Install Firebase CLI (if not installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Navigate to project
cd event_sphere

# Deploy rules
firebase deploy --only firestore:rules
```

## Verify Setup

1. **Check Authentication:**
   - Ensure you're logged in to the app
   - Your user must exist in Firestore `users` collection
   - Your user document must have `role: 'organization'`

2. **Verify Rules Are Deployed:**
   - Go to Firebase Console → Firestore → Rules
   - Check the "Last published" timestamp
   - Verify the rules match your `firestore.rules` file

3. **Test Again:**
   - Try creating an event again
   - The permission error should be resolved

## Troubleshooting

If you still get permission errors after deploying:

1. **Check your user document:**
   - Go to Firebase Console → Firestore Database
   - Check `users/{your-user-id}` document
   - Ensure it has a `role` field set to `'organization'`

2. **Verify authentication:**
   - Make sure you're logged in (not anonymous)
   - Check Firebase Console → Authentication

3. **Check rule syntax:**
   - Firebase Console → Firestore → Rules → "Test rules" to validate syntax

