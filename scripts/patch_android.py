#!/usr/bin/env python3
"""Configure the generated Android project for this app.

Run this AFTER generating the Android platform folder:

    flutter create --platforms=android --org com.habittracker --project-name habit_tracker .
    python3 scripts/patch_android.py

It edits only the generated Gradle and manifest files, and is safe to run
more than once. It:

  * enables core-library desugaring (required by flutter_local_notifications)
  * raises minSdk to 24 and turns on multidex
  * adds the notification permissions and the boot receivers so scheduled
    reminders survive a reboot
  * sets the visible app name to "Habit Tracker"
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP_DIR = os.path.join(ROOT, "android", "app")

MARKER = "habit-tracker additions"

GROOVY_BLOCK = """
// --- habit-tracker additions ---
android {
    defaultConfig {
        minSdkVersion 24
        multiDexEnabled true
    }
    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}
dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
}
"""

KTS_BLOCK = """
// --- habit-tracker additions ---
android {
    defaultConfig {
        minSdk = 24
        multiDexEnabled = true
    }
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
"""

PERMISSIONS = """    <!-- habit-tracker additions -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
"""

RECEIVERS = """        <!-- habit-tracker additions: scheduled reminder support -->
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
"""


def fail(message):
    print("ERROR: " + message, file=sys.stderr)
    sys.exit(1)


def patch_gradle():
    groovy = os.path.join(APP_DIR, "build.gradle")
    kts = os.path.join(APP_DIR, "build.gradle.kts")

    if os.path.exists(kts):
        path, block = kts, KTS_BLOCK
    elif os.path.exists(groovy):
        path, block = groovy, GROOVY_BLOCK
    else:
        fail("could not find android/app/build.gradle(.kts). "
             "Run `flutter create --platforms=android .` first.")

    with open(path, "r", encoding="utf-8") as fh:
        text = fh.read()

    if MARKER in text:
        print("Gradle already configured: " + os.path.relpath(path, ROOT))
        return

    with open(path, "a", encoding="utf-8") as fh:
        fh.write(block)
    print("Gradle configured: " + os.path.relpath(path, ROOT))


def patch_manifest():
    path = os.path.join(APP_DIR, "src", "main", "AndroidManifest.xml")
    if not os.path.exists(path):
        fail("could not find " + os.path.relpath(path, ROOT))

    with open(path, "r", encoding="utf-8") as fh:
        text = fh.read()

    if MARKER in text:
        print("Manifest already configured: " + os.path.relpath(path, ROOT))
        return

    # Permissions go just after the opening <manifest ...> tag.
    text = re.sub(
        r"(<manifest\b[^>]*>\s*\n)",
        r"\1" + PERMISSIONS,
        text,
        count=1,
    )

    # Receivers go just before the closing </application> tag.
    text = text.replace("    </application>", RECEIVERS + "    </application>", 1)

    # Visible app name.
    text = re.sub(r'android:label="[^"]*"', 'android:label="Habit Tracker"', text, count=1)

    with open(path, "w", encoding="utf-8") as fh:
        fh.write(text)
    print("Manifest configured: " + os.path.relpath(path, ROOT))


def main():
    if not os.path.isdir(APP_DIR):
        fail("the android/ folder is missing. "
             "Run `flutter create --platforms=android .` first.")
    patch_gradle()
    patch_manifest()
    print("Android project ready. Build with: flutter build apk --debug")


if __name__ == "__main__":
    main()
