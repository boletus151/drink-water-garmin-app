# Drink Water

**Bebe agua** is a standalone Garmin Connect IQ watch app for the **Forerunner 645 (non-Music)**, written in **Monkey C**, targeting API **3.1+**. The watch interface is in Spanish.

## What it does

- Sends scheduled hydration reminders without a phone connection.
- Stores an informational daily goal of **50-10,000 ml**; it does **not** track water intake.
- Supports reminder intervals of **15-60 minutes**, a same-day time window, and independently selected weekdays.
- Allows persistent configuration on the watch or through Connect IQ mobile settings.
- Shows the goal, schedule, enabled state, and next reminder on the main screen; a separate reminder screen displays the hydration prompt.

Defaults: reminders enabled, **2,000 ml**, every **60 minutes**, **09:00-21:00**, every day.

### Scheduling and limitations

Reminders follow local watch time, starting at the configured start time. The end time is a reminder slot only when it matches the interval cadence. Overnight windows are unsupported; start must precede end, and at least one day must be selected. Invalid settings suspend scheduling and display an error.

The background service requests Garmin's **system dialog to open the app** ("Recuerda beber agua"), not a custom notification over the watch face. Dismissing it does not disable future reminders. The app does not request sound, vibration, or backlight activation; firmware controls presentation, so alarm-level punctuality is not guaranteed.

The scheduler accepts up to **60 seconds** of delay, suppresses duplicate reminders, and respects Garmin's **five-minute minimum** between background executions. A slot may be delayed within that tolerance or skipped. Hourly checkpoints re-evaluate the schedule without displacing nearby reminders. Nonexistent daylight-saving times are skipped; repeated local slots are not notified twice. Time-zone changes may take approximately **65 minutes** to be reflected unless the app is reopened.

There is no server, analytics, intake history, or medical recommendation engine.

## Watch controls and settings

- Open the app once after installation. **START** toggles reminders; **UP** or **MENU** opens settings.
- **UP/DOWN** navigates or changes values; **START** selects, advances through digits, or saves. **BACK** returns to the previous digit or cancels from the first digit.
- The goal changes in **50 ml** steps. Interval and time editors use highlighted digits; times are displayed as **HH:MM**.
- In the days menu, **START** toggles the selected weekday. Exit to the watch face with **BACK**; reminders continue in the background.

Properties use schema version **3**. `startTime` and `endTime` store minutes since midnight (**09:30 = 570**), which is also the format used by mobile settings. `day1` through `day7` mean Monday through Sunday. Older schema markers 1 and 2 are accepted, but there is **no migration**: when upgrading from separate hour/minute properties or Sunday-first day numbering, reconfigure the times and weekdays.

## Architecture

The app uses an **MVC-style separation**, with Garmin input delegates as controllers and compiled XML layouts as presentation resources:

1. **Application:** initializes the main/reminder view, persists settings and foreground reminder state, and re-arms scheduling on lifecycle/settings changes.
2. **Model and services:** read and validate application properties, calculate local-calendar reminder slots, and register temporal background events.
3. **Background execution:** requests application wake for a due, non-duplicate reminder, schedules the next event, and returns its reminder key to the foreground through `Background.exit`. The service does not write properties or storage.
4. **UI:** views render current data; controllers own editor drafts, validation, saving, and navigation. Screens compose shared components rather than inheriting from other screens. Garmin manages menu navigation; XML defines headers, rows, and screen content.

### Source files

Paths below are relative to [source/](source/).

| Files | Purpose |
| --- | --- |
| [App/DrinkWaterApp.mc](source/App/DrinkWaterApp.mc) | Entry point, lifecycle, root-view switching, persistence, and scheduling-error handling. |
| [Model/Config.mc](source/Model/Config.mc) | `WaterConfig`, property loading, validation, shared limits, and debug flag. |
| [Service/Schedule.mc](source/Service/Schedule.mc) | Calendar calculations, due-slot keys, minimum spacing, checkpoints, and event registration. |
| [Service/WaterService.mc](source/Service/WaterService.mc) | Background callback, duplicate suppression, wake request, and result delivery. |
| [Style/Theme.mc](source/Style/Theme.mc) | Runtime colors and menu spacing constants. |
| [View/Common/LayoutView.mc](source/View/Common/LayoutView.mc), [RootView.mc](source/View/Common/RootView.mc) | Typed XML-element access, API 3.1-compatible visibility/drawing, and root-view lifecycle helpers. |
| [Controller/Common/RootController.mc](source/Controller/Common/RootController.mc) | Shared reminder toggle and settings navigation. |
| [View/Screens/WaterView.mc](source/View/Screens/WaterView.mc), [ReminderView.mc](source/View/Screens/ReminderView.mc) | Main status/schedule screen and separate reminder screen. |
| [Controller/Screens/WaterController.mc](source/Controller/Screens/WaterController.mc), [ReminderController.mc](source/Controller/Screens/ReminderController.mc) | Root-screen input delegates; the main controller also provides the next reminder for display. |
| [View/Screens/GoalView.mc](source/View/Screens/GoalView.mc), [IntervalView.mc](source/View/Screens/IntervalView.mc), [TimeView.mc](source/View/Screens/TimeView.mc) | Editor screens; one time view serves both start and end settings. |
| [Controller/Screens/GoalController.mc](source/Controller/Screens/GoalController.mc), [IntervalController.mc](source/Controller/Screens/IntervalController.mc), [TimeController.mc](source/Controller/Screens/TimeController.mc) | Setting-specific ranges, digit rules, and time conversion on save. |
| [View/Screens/GarminScreens/SettingsMenu.mc](source/View/Screens/GarminScreens/SettingsMenu.mc), [DaysMenu.mc](source/View/Screens/GarminScreens/DaysMenu.mc) | Native Garmin settings and weekday menus. |
| [Controller/Screens/GarminScreens/SettingsController.mc](source/Controller/Screens/GarminScreens/SettingsController.mc), [DaysController.mc](source/Controller/Screens/GarminScreens/DaysController.mc) | Open editors, toggle settings/days, and refresh menu values. |
| [Controller/Components/NumberController.mc](source/Controller/Components/NumberController.mc), [DigitController.mc](source/Controller/Components/DigitController.mc) | Shared draft editing, confirmation, cancellation, and button handling. |
| [View/Components/NumberEditor.mc](source/View/Components/NumberEditor.mc), [DigitEditor.mc](source/View/Components/DigitEditor.mc) | Reusable numeric presentation and active-digit/error rendering. |
| [View/Components/WaterFrame.mc](source/View/Components/WaterFrame.mc) | Shared root-screen header, errors, and control hints. |
| [View/Components/SettingsList.mc](source/View/Components/SettingsList.mc), [SettingsTitle.mc](source/View/Components/SettingsTitle.mc), [SettingsItem.mc](source/View/Components/SettingsItem.mc) | Menu value formatting/refresh, headers, and focused rows. |

### Resources and project files

| Files | Purpose |
| --- | --- |
| [resources/layouts/screens/](resources/layouts/screens/) | `water.xml`, `reminder.xml`, `goal.xml`, `interval.xml`, and `time.xml`: screen-specific layouts. |
| [resources/layouts/components/](resources/layouts/components/) | `water-frame.xml`, `settings-menu-header.xml`, `days-menu-header.xml`, and `menu-item.xml`: reusable UI layouts. |
| [resources/properties.xml](resources/properties.xml), [settings.xml](resources/settings.xml) | Persistent defaults/schema and mobile-settings fields/ranges. |
| [resources/strings.xml](resources/strings.xml) | Spanish UI text and background-accessible messages. |
| [resources/drawables.xml](resources/drawables.xml), [icon.svg](resources/icon.svg) | Background/focus drawables and launcher icon. |
| [manifest.xml](manifest.xml) | App identity, entry point, device, minimum API, language, and background permission. |
| [monkey.jungle](monkey.jungle) | Compiler source, test, resource, and manifest paths. |
| [Makefile](Makefile), [run-simulator.sh](run-simulator.sh) | Strict builds, simulator execution, tests, and export; the script builds before running. |
| [.vscode/launch.json](.vscode/launch.json) | Monkey C debugger configuration for `fr645`. |
| [tests/ScheduleTests.mc](tests/ScheduleTests.mc) | Regression tests for configuration/types, calendar boundaries, reminder tolerance/spacing/checkpoints, editor persistence, menu toggles, and screen rendering. Tests that modify settings restore them after failures. |

XML layouts use native labels/text areas and relative positions. Layout and theme changes require recompilation; keep XML colors consistent with the runtime palette.

## Prerequisites

The following walkthrough uses **macOS and Terminal**. The app targets only the **Forerunner 645 (non-Music)** with Connect IQ API **3.1.0+**; it is not a generic build for any Garmin watch. You can use the simulator without owning the watch.

### 1. Install the basic tools

- Install **Git and Make**. On macOS, run `xcode-select --install` if the Command Line Tools are not installed, and complete the installation dialog.
- Install a **Java 17 JDK** for your Mac's architecture, for example from [Eclipse Temurin](https://adoptium.net/temurin/releases/?version=17).
- Install [Visual Studio Code](https://code.visualstudio.com/). This guide uses Garmin's extension to generate the signing key and optionally debug the app.

Check that the tools are available:

```sh
git --version
make --version
/usr/libexec/java_home -v 17
```

The last command should print the Java 17 home directory. If it cannot find Java 17, finish installing the JDK before continuing.

### 2. Clone the application

```sh
git clone https://github.com/boletus151/drink-water-garmin-app.git
cd drink-water-garmin-app
```

Run the remaining build and simulator commands from this directory, which contains [Makefile](Makefile) and [monkey.jungle](monkey.jungle).

### 3. Install the Garmin SDK and device profile

1. Download the **Connect IQ SDK Manager** for your operating system from [Garmin's SDK page](https://developer.garmin.com/connect-iq/sdk/), accepting Garmin's license terms.
2. On macOS, open the downloaded disk image, copy SDK Manager to Applications, and launch it.
3. Sign in with your Garmin Connect account and complete the setup prompts.
4. In the **SDK** tab, download an SDK and select **Use as SDK** to make it active.
5. In the **Devices** tab, download **Forerunner 645** (`fr645`), not the Music variant. Wait for both downloads to finish.
6. Locate the installed SDK directory and keep its absolute path for step 5. It must contain `bin/monkeyc`, `bin/monkeydo`, and `bin/connectiq`; the SDK Manager application itself is not this directory.

The desktop SDK version is separate from the app's minimum watch API version (**3.1.0**). See Garmin's [Getting Started guide](https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/) for SDK Manager and extension setup.

### 4. Generate a developer signing key

Garmin requires a private **RSA 4096-bit developer key**, including for simulator builds. Generate it once and keep it outside the repository:

1. Open the cloned project folder in VS Code.
2. Open **Extensions**, search for **Monkey C**, and install the extension published by **Garmin**.
3. Create a directory for the key in Terminal:

   ```sh
   mkdir -p "$HOME/.local/share/drink-water-tools"
   ```

4. In VS Code, open the command palette with **Cmd+Shift+P** and run **Monkey C: Generate a Developer Key**.
5. Save the generated DER key as `developer_key.der` in the directory created above. In a file picker, **Cmd+Shift+G** lets you enter `~/.local/share/drink-water-tools/`.
6. In VS Code Settings, set **Monkey C: Developer Key Path** to that file if it is not already configured.
7. Run **Monkey C: Verify Installation** from the command palette and resolve any reported SDK, Java, or key issues before continuing.

If you already have a compatible private DER key, reuse it instead of generating another. Never commit or share the key, and keep a secure backup: updates to a published Connect IQ app must use the same signing key.

### 5. Configure and verify the tool paths

In Terminal, replace the SDK placeholder below with the directory from step 3:

```sh
export SDK_HOME="/absolute/path/to/installed/connectiq-sdk"
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
export DEVELOPER_KEY="$HOME/.local/share/drink-water-tools/developer_key.der"

"$JAVA_HOME/bin/java" -version
"$SDK_HOME/bin/monkeyc" --version
test -r "$DEVELOPER_KEY" && echo "Developer key found" || echo "Developer key missing: check DEVELOPER_KEY"
```

Java should report version 17, `monkeyc` should print its compiler version, and the key check should report `Developer key found`. Do not continue if a command fails; check the installation and paths first. If you saved your key elsewhere, adjust `DEVELOPER_KEY`.

Keep using this Terminal session for the following steps. For future sessions, repeat these exports or add them to your shell configuration (usually `~/.zshrc` on macOS). Setting the key path in VS Code does **not** configure Make: the terminal also needs `DEVELOPER_KEY`.

The [Makefile](Makefile) reads these variables and sets Java for its commands. Without overrides, it defaults to `~/.local/share/drink-water-tools/sdk`, `~/.local/share/drink-water-tools/java/Contents/Home`, and `~/.local/share/drink-water-tools/developer_key.der`. These tools are not included in the repository; the exports above let you use your own installation without moving it.

## Build, run, and install

### How the Garmin SDK is used

The app uses Garmin's SDK to compile Monkey C and XML resources (`monkeyc`), load programs and run tests in the simulator (`monkeydo`), and export a Connect IQ package. At runtime, it uses the Connect IQ application lifecycle, native views/input delegates, persistent properties/storage, and temporal background events. The `Background` permission is declared in [manifest.xml](manifest.xml).

Builds target **fr645**, use strict type checking (`-l 3`), and report compiler warnings (`-w`). [monkey.jungle](monkey.jungle) supplies the source, test, resource, and manifest paths.

### Build and export

```sh
make build          # bin/drink-water.prg; strict type checking (-l 3)
```

Wait for a successful build before proceeding. The `.prg` is the program used by the simulator and for USB installation. Optionally, `make package` produces `bin/drink-water.iq` for Connect IQ distribution; this package is not the file to copy directly to the watch.

### Using the simulator

Run these commands from the project directory in the Terminal session configured above:

1. Start Garmin's simulator and wait for its window to open:

   ```sh
   "$SDK_HOME/bin/connectiq"
   ```

   On macOS, this launcher opens the SDK's `ConnectIQ.app`.

2. Build and load the app:

   ```sh
   ./run-simulator.sh
   ```

   The script builds first, then calls `make run` to load the program on the **fr645** simulated device. It does **not** start the simulator. To reload an already-built program without rebuilding, use `make run`; source or XML changes require a new build.

   You should see the Spanish **Bebe agua** main screen with the goal and schedule. If loading fails, check that the simulator is open, the `fr645` device profile has finished downloading, and the terminal is using the intended SDK.

3. Use the simulated watch buttons as described in **Watch controls and settings**: **START** toggles reminders or confirms a selection, **UP/MENU** opens settings, **UP/DOWN** changes values, and **BACK** returns or cancels. Check the goal, interval, time window, and weekdays, then return to the watch face to exercise background reminders.

For interactive debugging in VS Code, install/configure Garmin's Monkey C extension with your SDK and developer key, select **Debug Bebe agua (Forerunner 645)**, and press **F5**. The configuration in [.vscode/launch.json](.vscode/launch.json) targets `fr645` and pauses at launch (`stopAtLaunch`); resume execution to interact with the app.

`Config.DEBUG` in [source/Model/Config.mc](source/Model/Config.mc) is currently **false**. Enabling it and rebuilding schedules a one-off test reminder approximately 60 seconds after opening, outside normal day/time restrictions but still respecting Garmin's minimum spacing. This is useful for checking the background wake dialog without waiting for a normal reminder slot. Keep it disabled for normal use.

To run the regression tests explicitly, leave the simulator open and execute:

```sh
make test
```

The test target compiles a separate `bin/drink-water-tests.prg`, requires a complete `PASSED` summary with no failures/errors, and records output in `bin/test-output.log`; it handles the known macOS `monkeydo` exit-code-1 anomaly only when that summary is present.

The simulator is useful for UI, settings, and scheduling checks, but does not establish real-watch notification timing, firmware behavior during activities/Do Not Disturb, or battery consumption. Clock changes also need real-device validation.

### Installing on the watch

1. Confirm that the watch is a **Forerunner 645 (non-Music)** and update its firmware if necessary. Other devices need their own manifest target and compatible build.
2. Leave `Config.DEBUG` disabled and run `make build`. Use the resulting `bin/drink-water.prg`, not the test program or the `.iq` package.
3. Connect the watch to your computer with a **USB data cable**. Wait for its storage to appear in Finder; if it does not, check the cable and the watch's USB mode.
4. Open the watch's **GARMIN/APPS** folder and copy `bin/drink-water.prg` into it.
5. Safely eject the watch, disconnect the cable, and wait for it to finish processing the app.
6. On the watch, press **START**, find **Bebe agua** in the app list, and open it once to initialize scheduling.
7. Check the goal, interval, start/end times, weekdays, and enabled state. Exit with **BACK** to leave reminders running in the background.

If the app does not appear or cannot open, check the device model, firmware, successful build output, and destination folder. The simulator cannot guarantee real-device compatibility or background behavior.

Mobile settings depend on Connect IQ settings metadata; USB installation is not Connect IQ Store publication and does not by itself guarantee access to those settings in the mobile app. All settings can be configured on the watch. Store publication is a separate, manual step. Generated files live in `bin/`, not in the source tree.
