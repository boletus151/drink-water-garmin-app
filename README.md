# Drink Water

**Drink Water**, displayed on the watch as **Bebe Agua App** (with a line break before **App**), is a standalone Garmin Connect IQ watch app for the **Forerunner 645 (non-Music)**, written in **Monkey C**, targeting API **3.1+**. The watch interface is in Spanish.

`AppTitle` supplies the two-line root-screen title; `AppName` remains a single line for the launcher and settings-menu row.

## What it does

- Sends scheduled hydration reminders without a phone connection.
- Tracks manually registered water intake against a daily goal of **50-10,000 ml**.
- Uses a configurable serving of **100, 150, 200, or 250 ml**. Reaching or exceeding the goal stops reminders for the rest of that local day.
- Supports reminder intervals of **15-60 minutes**, a same-day time window, and independently selected weekdays.
- Allows persistent configuration on the watch or through Connect IQ mobile settings.
- Shows **Objetivo**, **Llevas**, the schedule, and the next reminder on the main screen. The **START: activar/desactivar** hint indicates reminder state. The in-app reminder screen displays the hydration prompt and remaining milliliters, never below zero. A dedicated **Objetivo cumplido** screen appears when the daily goal is reached or exceeded.

Defaults: reminders enabled, **2,000 ml** daily goal, **100 ml** per serving, every **60 minutes**, **09:00-21:00**, every day.

### The reminder dialog: a Connect IQ limitation

When a reminder is due while the app is closed, the background service requests Garmin's **system dialog to open the app**, displaying:

> Hora de beber agua  
> ¿Abrir para registrar?

**The dialog itself is the reminder; opening the app is optional.**

- **Accept:** open the app, then use **UP/MENU → Registrar toma** to record the configured serving.
- **Decline:** dismiss the message without opening the app. Future reminders remain active.
- **Neither choice records water automatically.** Intake is registered only when you select **Registrar toma**.

Connect IQ requires confirmation to open an app or widget from the background. The app cannot automatically accept the dialog or bypass it. This is a platform limitation, not specific to the Forerunner 645; converting the app to a widget or changing watches does not remove the confirmation required by this API. See Garmin's [requestApplicationWake documentation](https://developer.garmin.com/connect-iq/api-docs/Toybox/Background.html#requestApplicationWake-instance_function).

Only the message text is supplied by the app. Garmin controls the dialog's layout, colors, font, buttons, and presentation; it cannot use our custom in-app screen design. This is not a custom notification over the watch face. The app does not request sound, vibration, or backlight activation, so alarm-level presentation or punctuality is not guaranteed.

### Scheduling and limitations

Reminders follow local watch time, starting at the configured start time. The end time is a reminder slot only when it matches the interval cadence. Overnight windows are unsupported; start must precede end, and at least one day must be selected. Invalid settings suspend scheduling and display an error.

The daily total persists when the app closes or the watch restarts. A different local calendar date starts at **0 ml**; only the current daily aggregate is retained, with no intake history. Reaching or exceeding the goal suppresses that day's reminders, including debug reminders, without changing the enabled setting. Future reminders resume on the next selected day within the configured time window. Manually disabled reminders stay disabled.

The total records only what you enter; the app cannot detect drinking automatically. You can still register servings after reaching the goal or while reminders are disabled. Totals are not capped at the goal. Changing the serving size affects only future entries; changing the goal immediately re-evaluates scheduling against the existing daily total.

The scheduler accepts up to **60 seconds** of delay, suppresses duplicate reminders, and respects Garmin's **five-minute minimum** between background executions. A slot may be delayed within that tolerance or skipped. Hourly checkpoints re-evaluate the schedule without displacing nearby reminders. Nonexistent daylight-saving times are skipped; repeated local slots are not notified twice. Time-zone changes may take approximately **65 minutes** to be reflected unless the app is reopened.

There is no server, analytics, intake history, or medical recommendation engine.

## Watch controls and settings

- Open the app once after installation. **START** toggles reminders; **UP** or **MENU** opens settings.
- Set **Cantidad toma (ml)** to **100, 150, 200, or 250** using **UP/DOWN**, then save with **START**. Changes are in **50 ml** steps.
- Whenever you drink that amount, open the menu and select its first option, **Registrar toma**. Its subtitle shows the amount to add. Each successful entry briefly flashes the menu background turquoise; the menu stays open for further entries. Return with **BACK** to see the updated total (for example, **Objetivo: 2000 ml**, **Llevas: 150 ml**), unless the goal has already been reached. Registration is also available from the reminder and goal-completed screens.
- At or above the goal, with valid settings and no scheduling error, the app shows **¡Enhorabuena! Objetivo cumplido**, the goal amount, and **Sin mas avisos hoy**, even if reminders are manually disabled. It hides the consumed-total row and control hints, but **START** still toggles reminders and **UP/MENU** still opens settings. The main screen returns when a new local day begins or the goal is raised above the daily total.
- **UP/DOWN** navigates or changes values; **START** selects, advances through digits, or saves. **BACK** returns to the previous digit or cancels from the first digit.
- The goal changes in **50 ml** steps on the watch. Interval and time editors use highlighted digits; times are displayed as **HH:MM**.
- In the days menu, **START** toggles the selected weekday. Exit to the watch face with **BACK**; reminders continue in the background.

Properties use schema version **3**. `servingMl` defaults to 100 and has the same four choices in mobile settings. `startTime` and `endTime` store minutes since midnight (**09:30 = 570**), also used by mobile settings. `day1` through `day7` mean Monday through Sunday. Older schema markers 1 and 2 are accepted, but there is **no migration**: when upgrading from separate hour/minute properties or Sunday-first day numbering, reconfigure the times and weekdays.

## Architecture

The app uses an **MVC-style separation**, with Garmin input delegates as controllers and compiled XML layouts as presentation resources.

Each XML layout lives beside the Monkey C view or component that consumes it, under [source/View/](source/View/). Screens have their own folders; shared components follow the same convention. Global strings, properties, settings, and drawables remain in [resources/](resources/). [monkey.jungle](monkey.jungle) includes resources from both locations.

1. **Application:** initializes the main/reminder view, persists settings, daily intake, and foreground reminder state, and re-arms scheduling on lifecycle/settings/intake changes.
2. **Model and services:** validate properties and daily intake, calculate local-calendar reminder slots excluding completed days, and register temporal background events.
3. **Background execution:** requests Garmin's reminder/open-app dialog for a due, non-duplicate reminder, schedules the next event, and returns its reminder key through `Background.exit`. The service does not write properties or storage.
4. **UI:** views render current data; controllers own editor drafts, validation, saving, and navigation. Screens compose shared components rather than inheriting from other screens. Garmin manages menu navigation; XML defines headers, rows, and screen content.

### Source files

Paths below are relative to [source/](source/).

| Files | Purpose |
| --- | --- |
| [App/DrinkWaterApp.mc](source/App/DrinkWaterApp.mc) | Entry point, lifecycle, root-view switching, persistence, and scheduling-error handling. |
| [App/ScreenDebug.mc](source/App/ScreenDebug.mc) | Startup-screen previews using real views and editor factories. |
| [App/DebugConfig.mc](source/App/DebugConfig.mc) | Default preview/reminder flags; debug scripts substitute temporary configuration. |
| [Model/Config.mc](source/Model/Config.mc) | `WaterConfig`, property loading, validation, and shared limits. |
| [Model/Intake.mc](source/Model/Intake.mc) | Persistent daily total, local-date keys, rollover, and stored-data validation. |
| [Service/Schedule.mc](source/Service/Schedule.mc) | Calendar calculations, due-slot keys, spacing, checkpoints, and event registration. |
| [Service/WaterService.mc](source/Service/WaterService.mc) | Background callback, duplicate suppression, system-dialog request, and result delivery. |
| [Style/Theme.mc](source/Style/Theme.mc) | Runtime colors and spacing. |
| [View/Common/LayoutView.mc](source/View/Common/LayoutView.mc), [RootView.mc](source/View/Common/RootView.mc) | Typed XML access, visibility/drawing, and root-view lifecycle helpers. |
| [View/Common/StackText.mc](source/View/Common/StackText.mc) | Shared text drawable that measures and wraps text for vertical layouts. |
| [Controller/Common/RootController.mc](source/Controller/Common/RootController.mc) | Shared reminder toggle and settings navigation. |
| [View/Screens/Water/WaterView.mc](source/View/Screens/Water/WaterView.mc), [Reminder/ReminderView.mc](source/View/Screens/Reminder/ReminderView.mc), [GoalReached/GoalReachedView.mc](source/View/Screens/GoalReached/GoalReachedView.mc) | Main, reminder, and completed-goal screens. |
| [Controller/Screens/WaterController.mc](source/Controller/Screens/WaterController.mc), [ReminderController.mc](source/Controller/Screens/ReminderController.mc) | Root-screen input; the main controller also provides the next reminder. |
| [View/Screens/Goal/GoalView.mc](source/View/Screens/Goal/GoalView.mc), [Interval/IntervalView.mc](source/View/Screens/Interval/IntervalView.mc), [Time/TimeView.mc](source/View/Screens/Time/TimeView.mc) | Editors; one time view serves start and end settings. |
| [Controller/Screens/GoalController.mc](source/Controller/Screens/GoalController.mc), [IntervalController.mc](source/Controller/Screens/IntervalController.mc), [TimeController.mc](source/Controller/Screens/TimeController.mc) | Editor ranges, digit rules, and time conversion. |
| [Controller/Screens/ServingController.mc](source/Controller/Screens/ServingController.mc), [View/Screens/Serving/ServingView.mc](source/View/Screens/Serving/ServingView.mc) | Serving editor with 50 ml steps and shared numeric presentation. |
| [View/Screens/GarminScreens/SettingsMenu.mc](source/View/Screens/GarminScreens/SettingsMenu.mc), [DaysMenu.mc](source/View/Screens/GarminScreens/DaysMenu.mc) | Native Garmin settings and weekday menus. |
| [Controller/Screens/GarminScreens/SettingsController.mc](source/Controller/Screens/GarminScreens/SettingsController.mc), [DaysController.mc](source/Controller/Screens/GarminScreens/DaysController.mc) | Editor navigation, menu toggles, and value refresh. |
| [Controller/Components/NumberController.mc](source/Controller/Components/NumberController.mc), [DigitController.mc](source/Controller/Components/DigitController.mc) | Shared draft editing, saving, cancellation, and button handling. |
| [View/Components/NumberEditor.mc](source/View/Components/NumberEditor.mc), [DigitEditor.mc](source/View/Components/DigitEditor.mc) | Numeric presentation, highlighted digits, and errors. |
| [View/Components/WaterFrame/WaterFrame.mc](source/View/Components/WaterFrame/WaterFrame.mc) | Shared root-screen header, errors, and control hints. |
| [View/Components/SettingsList.mc](source/View/Components/SettingsList.mc), [SettingsTitle/SettingsTitle.mc](source/View/Components/SettingsTitle/SettingsTitle.mc), [SettingsItem/SettingsItem.mc](source/View/Components/SettingsItem/SettingsItem.mc) | Menu formatting, headers, and focused rows. |

### Resources and project files

| Files | Purpose |
| --- | --- |
| [source/View/Screens/](source/View/Screens/), [source/View/Components/](source/View/Components/) | Screen/component XML layouts beside their Monkey C code. |
| [resources/properties.xml](resources/properties.xml), [settings.xml](resources/settings.xml) | Persistent defaults/schema and mobile settings. |
| [resources/strings.xml](resources/strings.xml) | Spanish UI text and background messages. |
| [resources/drawables.xml](resources/drawables.xml), [icon.svg](resources/icon.svg) | Background/focus drawables and launcher icon. |
| [manifest.xml](manifest.xml) | App identity, entry point, device, API, language, and background permission. |
| [monkey.jungle](monkey.jungle) | Compiler source, test, resource, and manifest paths. |
| [Makefile](Makefile), [run-simulator.sh](run-simulator.sh) | Strict builds, simulator execution, tests, and export. |
| [run-screen-debug.sh](run-screen-debug.sh) | Screen-preview build and launch with accelerated reminders. |
| [z_debug-launch-helper.sh](z_debug-launch-helper.sh) | Shared temporary debug configuration, compilation, loading, and cleanup. |
| [.vscode/launch.json](.vscode/launch.json) | Monkey C debugger configuration for `fr645`. |
| [tests/ScheduleTests.mc](tests/ScheduleTests.mc) | Configuration, scheduling, intake, editors, menus, and screen regressions. Tests restore modified settings/storage after failures. |

XML layouts use `StackText` labels without coordinates. `LayoutView.setVerticalLayout` groups their IDs into header, content, and footer rows, measures/wraps text, skips hidden elements, and centers content between the header and controls. IDs in the same row remain horizontal (for example, time digits); root-screen content follows XML order through `WaterFrame`.

Editors and menus use 6 px `Theme.STACK_GAP` spacing; root screens use 2 px `Theme.ROOT_STACK_GAP` and a 5 px outer margin on the 240 px display. Strings can include line breaks using `&#10;`, but their total height must fit. Overflow raises an explicit layout error rather than overlapping controls. Recompile layout/theme changes and keep XML colors consistent with the runtime palette.

Editors call `LayoutView.setEditorLayout` with their XML layout, drawing context, and content rows. The shared helper configures title/hints and the outer margin, avoiding repeated positioning formulas.

## Prerequisites

The following walkthrough uses **macOS and Terminal**. You can use the simulator without owning the watch.

### 1. Install the basic tools

- Install **Git and Make** with `xcode-select --install` if the Command Line Tools are missing, and complete the installation dialog.
- Install a **Java 17 JDK** for your Mac's architecture, for example from [Eclipse Temurin](https://adoptium.net/temurin/releases/?version=17).
- Install [Visual Studio Code](https://code.visualstudio.com/).

Check that the tools are available:

```sh
git --version
make --version
/usr/libexec/java_home -v 17
```

The last command should print the Java 17 home directory. Resolve missing tools before continuing.

### 2. Clone the application

```sh
git clone https://github.com/boletus151/drink-water-garmin-app.git
cd drink-water-garmin-app
```

Run the following build and simulator commands from this project directory.

### 3. Install the Garmin SDK and device profile

1. Download **Connect IQ SDK Manager** from [Garmin's SDK page](https://developer.garmin.com/connect-iq/sdk/), accepting Garmin's license terms.
2. On macOS, open the disk image, copy SDK Manager to Applications, and launch it.
3. Sign in with your Garmin Connect account and complete setup.
4. In **SDK**, download an SDK and select **Use as SDK**.
5. In **Devices**, download **Forerunner 645** (`fr645`), not the Music variant. Wait for both downloads to finish.
6. Keep the installed SDK directory's absolute path for step 5. It must contain `bin/monkeyc`, `bin/monkeydo`, and `bin/connectiq`; SDK Manager itself is not this directory.

The desktop SDK version is separate from the minimum watch API (**3.1.0**). See Garmin's [Getting Started guide](https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/) for SDK Manager and extension setup.

### 4. Generate a developer signing key

Garmin requires a private **RSA 4096-bit developer key**, including for simulator builds. Generate it once and keep it outside the repository:

1. Open the cloned project in VS Code.
2. Install the **Monkey C** extension published by **Garmin**.
3. Create a directory for the key:

   ```sh
   mkdir -p "$HOME/.local/share/drink-water-tools"
   ```

4. Run **Monkey C: Generate a Developer Key** from the command palette (**Cmd+Shift+P**).
5. Save it as `developer_key.der` in that directory. **Cmd+Shift+G** in the file picker lets you enter `~/.local/share/drink-water-tools/`.
6. Set **Monkey C: Developer Key Path** in VS Code Settings if needed.
7. Run **Monkey C: Verify Installation** and resolve SDK, Java, or key issues.

Reuse an existing compatible DER key instead of generating another. Never commit or share it, and keep a secure backup: updates to a published app must use the same signing key.

### 5. Configure and verify tool paths

Replace the SDK placeholder with the installed directory from step 3:

```sh
export SDK_HOME="/absolute/path/to/installed/connectiq-sdk"
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
export DEVELOPER_KEY="$HOME/.local/share/drink-water-tools/developer_key.der"

"$JAVA_HOME/bin/java" -version
"$SDK_HOME/bin/monkeyc" --version
test -r "$DEVELOPER_KEY" && echo "Developer key found" || echo "Developer key missing: check DEVELOPER_KEY"
```

Java should report version 17, `monkeyc` its compiler version, and the key check **Developer key found**. If a command fails, correct the path or installation before continuing.

Keep using this Terminal session. For future sessions, repeat the exports or add them to your shell configuration (usually `~/.zshrc`). Setting the key path in VS Code does **not** configure Make.

Without overrides, [Makefile](Makefile) uses `~/.local/share/drink-water-tools/sdk`, `~/.local/share/drink-water-tools/java/Contents/Home`, and `~/.local/share/drink-water-tools/developer_key.der`. Tools are not included in the repository; the exports let you use another installation without moving it.

## Build, run, and install

### Build and export

Garmin's SDK compiles Monkey C/XML with `monkeyc` and loads programs/tests with `monkeydo`. Builds target **fr645**, use strict type checking (`-l 3`), and report compiler warnings (`-w`).

```sh
make build          # bin/drink-water.prg
make package        # Optional: bin/drink-water.iq for Connect IQ distribution
```

Wait for a successful build. The `.prg` is used by the simulator and for USB installation; the `.iq` package is not the file to copy directly to the watch.

### Using the simulator

1. Start Garmin's simulator and wait for its window:

   ```sh
   "$SDK_HOME/bin/connectiq"
   ```

   On macOS, this launcher opens the SDK's `ConnectIQ.app`.

2. Build and load the app:

   ```sh
   ./run-simulator.sh
   ```

   You should see **Bebe Agua App**, with goal, consumed total, schedule, and next reminder. If loading fails, check that the simulator is open, the `fr645` profile has finished downloading, and Terminal uses the intended SDK.

3. Try the watch controls. Starting with a zero daily total, set the goal to **250 ml** and the serving to **150 ml**. Select **Registrar toma**, then **BACK**: the main screen should show **Objetivo: 250 ml** and **Llevas: 150 ml**.
4. Register another serving and return: **Objetivo cumplido** should show **250 ml** and **Sin mas avisos hoy**, without a consumed-total row or control hints.
5. Raise the goal to **350 ml** to return to the main screen and confirm **Llevas: 300 ml**. Restore your intended settings afterward, then exit to the watch face to exercise background reminders.

### Simulator script reference

Both scripts resolve paths relative to their own directory and require an already-running simulator. They rebuild on every launch, stop if compilation fails, and do not run tests or attach a debugger.

| Command | Behavior | Executable |
| --- | --- | --- |
| `./run-simulator.sh` | Build/run the default configuration | `bin/drink-water.prg` |
| `./run-simulator.sh debug` | Accelerated reminders with normal startup-screen selection | `bin/drink-water-debug.prg` |
| `./run-screen-debug.sh screen` | Preview the required screen with accelerated reminders | `bin/drink-water-debug.prg` |
| `make run` | Reload the existing normal build without rebuilding | `bin/drink-water.prg` |
| `make debug-run` | Reload whichever debug mode was built last | `bin/drink-water-debug.prg` |

Pass only the optional `debug` argument to the simulator launcher, or exactly one screen name to the screen launcher. Configure paths through environment variables, for example `SDK_HOME="/path/to/sdk" ./run-screen-debug.sh goal`; additional arguments and Make variable assignments are rejected. Source/XML changes require rebuilding, not just `make run`.

Debug launchers share [z_debug-launch-helper.sh](z_debug-launch-helper.sh), create temporary configuration, and never edit the normal defaults or overwrite the normal executable. Temporary files are cleaned up on exit, including failures or interruption; compiled programs and settings changed through the app persist.

### Previewing a specific screen

With the simulator open:

```sh
./run-screen-debug.sh goal
./run-screen-debug.sh reminder
./run-screen-debug.sh startTime
```

Available screens: `water`, `reminder`, `goalReached`, `goal`, `serving`, `interval`, `startTime`, `endTime`, `settings`, and `days`. The time options share a layout but use their respective titles/values. Unknown names fail explicitly.

The screen name is mandatory; [debug-screen.conf](debug-screen.conf) is no longer read. The former `run-debug.sh` and `run-simulator.sh --screen` interfaces have been replaced by [run-screen-debug.sh](run-screen-debug.sh).

The terminal should print `DrinkWater DEBUG: pantalla goal` (or the selected name). The command normally stays active until the app closes. If the simulator remains at the Garmin logo without that message, interrupt the script, restart the simulator, and retry; the SDK loader can remain waiting without reporting an error.

For persistent previews in regular non-release builds or VS Code debugging, edit [source/App/DebugConfig.mc](source/App/DebugConfig.mc):

```monkeyc
const SCREEN_ENABLED = true;
const SCREEN = "goal";
```

Then rebuild with `./run-simulator.sh`. Set `SCREEN_ENABLED = false` afterward to restore normal startup and automatic screen switching.

Preview mode opens the real view with its normal controller. Persistent previews without accelerated debug use current saved settings/intake; the screen launcher uses the fixed debug goal and separate intake described below. Controls still save changes, except for the fixed debug goal. Automatic root-screen switching is suppressed for the entire preview session, so reminders or goal updates do not replace the selected screen. Saving/cancelling an editor used as the initial screen closes the app; editors opened from a menu return to it.

`./run-screen-debug.sh goalReached` previews that layout even though debug intake starts at **1800 ml**. It does not complete the goal or suppress reminders; use normal startup in accelerated mode to check the actual transition.

The isolated debug launchers ignore persistent preview defaults. Persistent previews are independent of `DebugConfig.DEBUG`; release builds, including `make package`, disable both preview and accelerated reminder features.

For interactive debugging, configure Garmin's Monkey C extension with your SDK/key, select **Debug Bebe agua (Forerunner 645)** in VS Code, and press **F5**. [.vscode/launch.json](.vscode/launch.json) pauses at launch (`stopAtLaunch`); resume to interact with the app.

### Accelerated reminder debug mode

```sh
./run-simulator.sh debug  # Normal startup, accelerated reminders
./run-simulator.sh        # Return to the normal build
```

This mode fixes the goal at **2000 ml** without changing the saved normal goal. Each app opening initializes a separate `debugDailyIntake` to **1800 ml** for the current day. Registering servings increases only that debug total, never real `dailyIntake`. The debug goal cannot be edited. Other settings are shared: serving, interval, times, weekdays, and enabled-state changes persist in normal mode. Merely launching debug leaves the normal goal, interval, and intake unchanged.

The first reminder targets the next minute boundary (normally 1-60 seconds after opening), outside normal day/time/interval restrictions but still respecting enabled/valid settings and the daily goal. Background callbacks re-arm the next reminder for the earliest allowed time, respecting Garmin's **five-minute minimum** between executions. A recent background execution can delay a reminder. Scheduling uses the registered event time; callback validation uses `Background.getLastTemporalEventTime()` because the one-shot registration may already be cleared when it fires.

The terminal prints `DrinkWater DEBUG: objetivo 2000 ml, consumo inicial 1800 ml` at startup and `DrinkWater DEBUG: aviso en ... s` when scheduling. Exit to the watch face to observe the system reminder dialog described above.

To check completion, register two **100 ml** servings or one **200 ml** serving and return from settings. With normal startup in debug mode, the completed-goal screen appears and reminders stop for that day. **Do not reopen the app during this check:** opening debug resets intake to 1800 ml and can enable reminders again.

Entering the in-app reminder screen prints `DrinkWater INFO: pantalla de recordatorio visible`, including during previews or when returning from a menu. This indicates screen entry, not merely scheduling or requesting the system dialog.

### Regression tests and real-device checks

To run tests explicitly, leave the simulator open:

```sh
make test
```

This compiles a separate `bin/drink-water-tests.prg`, requires a complete `PASSED` summary with no failures/errors, and writes `bin/test-output.log`. It handles the known macOS `monkeydo` exit-code-1 anomaly only when that successful summary is present.

The simulator is useful for UI, settings, and scheduling checks, but cannot establish real-watch dialog presentation, timing during activities/Do Not Disturb, or battery consumption. Clock changes also need real-device validation.

### Installing on the watch

1. Confirm the watch is a **Forerunner 645 (non-Music)** and update its firmware if needed. Other devices require a manifest target, matching Makefile device IDs, and compatible layouts/controls.
2. Keep defaults in [source/App/DebugConfig.mc](source/App/DebugConfig.mc) disabled and run `make build`. Use **bin/drink-water.prg**, not a debug/test program or the `.iq` package.
3. Connect with a **USB data cable** and wait for storage to appear in Finder. If it does not, check the cable and watch USB mode.
4. Copy the program into the watch's **GARMIN/APPS** folder.
5. Safely eject, disconnect, and wait for the watch to process the app.
6. Press **START**, find **Bebe Agua App**, and open it once to initialize scheduling.
7. Check goal, serving, interval, times, weekdays, and enabled state. Use **Registrar toma** after drinking; exit with **BACK** for background reminders.

If the app does not appear or open, check the model, firmware, build output, and destination folder. Mobile settings depend on Connect IQ metadata; USB installation does not guarantee access to them. All settings can be configured on the watch. Store publication is a separate manual step; generated files live in `bin/`.
