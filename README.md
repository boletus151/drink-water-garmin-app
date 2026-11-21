# Drink Water

**Bebe agua** is a standalone Garmin Connect IQ watch app for the **Forerunner 645 (non-Music)**, written in **Monkey C**, targeting API **3.1+**. The watch interface is in Spanish.

## What it does

- Sends scheduled hydration reminders without a phone connection.
- Tracks manually registered water intake against a daily goal of **50-10,000 ml**.
- Uses a configurable serving of **100, 150, 200, or 250 ml**. Reaching or exceeding the goal stops reminders for the rest of that local day.
- Supports reminder intervals of **15-60 minutes**, a same-day time window, and independently selected weekdays.
- Allows persistent configuration on the watch or through Connect IQ mobile settings.
- Shows separate **Objetivo** and **Llevas** labels, schedule, and next reminder on the main screen. The **START: activar/desactivar** control indicates reminder state, without a redundant status row, leaving room for four vertically stacked content rows. The reminder screen displays the hydration prompt and **Quedan** milliliters, never below zero. A dedicated **Objetivo cumplido** screen appears when the daily goal is reached or exceeded.

Defaults: reminders enabled, **2,000 ml** daily goal, **100 ml** per serving, every **60 minutes**, **09:00-21:00**, every day.

### Scheduling and limitations

Reminders follow local watch time, starting at the configured start time. The end time is a reminder slot only when it matches the interval cadence. Overnight windows are unsupported; start must precede end, and at least one day must be selected. Invalid settings suspend scheduling and display an error.

The daily total persists when the app closes or the watch restarts. A different local calendar date starts at **0 ml**; only the current daily aggregate is used, with no intake history. Reaching or exceeding the goal suppresses that day's reminders, including debug reminders, without changing the enabled setting. Future reminders remain scheduled and resume on the next selected day within the configured time window. Manually disabled reminders stay disabled.

The total records only what you enter; the app cannot detect drinking automatically. You can still register servings after reaching the goal or while reminders are disabled. Totals are not capped at the goal. Changing the serving size affects only future entries; changing the goal immediately re-evaluates reminder scheduling against the existing daily total.

The background service requests Garmin's **system dialog to open the app** ("Recuerda beber agua"), not a custom notification over the watch face. Dismissing it does not disable future reminders. The app does not request sound, vibration, or backlight activation; firmware controls presentation, so alarm-level punctuality is not guaranteed.

The scheduler accepts up to **60 seconds** of delay, suppresses duplicate reminders, and respects Garmin's **five-minute minimum** between background executions. A slot may be delayed within that tolerance or skipped. Hourly checkpoints re-evaluate the schedule without displacing nearby reminders. Nonexistent daylight-saving times are skipped; repeated local slots are not notified twice. Time-zone changes may take approximately **65 minutes** to be reflected unless the app is reopened.

There is no server, analytics, intake history, or medical recommendation engine.

## Watch controls and settings

- Open the app once after installation. **START** toggles reminders; **UP** or **MENU** opens settings.
- Set **Cantidad toma (ml)** to **100, 150, 200, or 250** using **UP/DOWN**, then save with **START**. Changes are always in **50 ml** steps.
- Whenever you drink that amount, open the menu and select its first option, **Registrar toma**. Its subtitle shows the amount to add. Each successful entry briefly flashes the menu background turquoise for 350 ms, then restores its normal colors; the menu stays open for further entries. Return with **BACK** to see the updated total (for example, **Objetivo: 2000 ml**, **Llevas: 150 ml**). This is also available from the reminder and goal-completed screens.
- At or above the goal, the app shows a dedicated **Objetivo cumplido** screen with the goal, consumed amount, and **Sin mas avisos hoy**, even if reminders are manually disabled. This screen hides the **START** and **UP** control hints; **START** still toggles reminders and **UP/MENU** still opens settings. The main screen returns when a new local day begins or the goal is raised above the daily total; the screen selection is re-evaluated on opening, returning from settings, and foreground redraws.
- **UP/DOWN** navigates or changes values; **START** selects, advances through digits, or saves. **BACK** returns to the previous digit or cancels from the first digit.
- The goal changes in **50 ml** steps. Interval and time editors use highlighted digits; times are displayed as **HH:MM**.
- In the days menu, **START** toggles the selected weekday. Exit to the watch face with **BACK**; reminders continue in the background.

Properties use schema version **3**. `servingMl` defaults to 100 and is restricted to the same four choices in mobile settings. `startTime` and `endTime` store minutes since midnight (**09:30 = 570**), which is also the format used by mobile settings. `day1` through `day7` mean Monday through Sunday. Older schema markers 1 and 2 are accepted, but there is **no migration**: when upgrading from separate hour/minute properties or Sunday-first day numbering, reconfigure the times and weekdays.

## Architecture

The app uses an **MVC-style separation**, with Garmin input delegates as controllers and compiled XML layouts as presentation resources:

Each XML layout lives beside the Monkey C view or component that consumes it, under `source/View`. Screens have their own folders (for example, `source/View/Screens/Water/` contains `WaterView.mc` and `water.xml`). Shared layout components follow the same convention. Global strings, properties, settings, and drawables remain in `resources/`. The compiler reads resources from both locations through [monkey.jungle](monkey.jungle).

1. **Application:** initializes the main/reminder view, persists settings, daily intake, and foreground reminder state, and re-arms scheduling on lifecycle/settings/intake changes.
2. **Model and services:** read and validate application properties and the daily intake aggregate, calculate local-calendar reminder slots excluding completed days, and register temporal background events.
3. **Background execution:** requests application wake for a due, non-duplicate reminder, schedules the next event, and returns its reminder key to the foreground through `Background.exit`. The service does not write properties or storage.
4. **UI:** views render current data; controllers own editor drafts, validation, saving, and navigation. Screens compose shared components rather than inheriting from other screens. Garmin manages menu navigation; XML defines headers, rows, and screen content.

### Source files

Paths below are relative to [source/](source/).

| Files | Purpose |
| --- | --- |
| [App/DrinkWaterApp.mc](source/App/DrinkWaterApp.mc) | Entry point, lifecycle, root-view switching, persistence, and scheduling-error handling. |
| [App/ScreenDebug.mc](source/App/ScreenDebug.mc) | Optional startup-screen selection for non-release builds; reuses real views and editor factories. |
| [App/DebugConfig.mc](source/App/DebugConfig.mc) | Default preview/reminder debug flags, also available to the background service; scripts substitute a temporary configuration at compile time. |
| [Model/Config.mc](source/Model/Config.mc) | `WaterConfig`, property loading, validation, and shared limits. |
| [Model/Intake.mc](source/Model/Intake.mc) | Persistent daily-total reading, local-date keys, rollover, and stored-data validation; storage writes remain in the foreground application. |
| [Service/Schedule.mc](source/Service/Schedule.mc) | Calendar calculations, due-slot keys, minimum spacing, checkpoints, and event registration. |
| [Service/WaterService.mc](source/Service/WaterService.mc) | Background callback, duplicate suppression, wake request, and result delivery. |
| [Style/Theme.mc](source/Style/Theme.mc) | Runtime colors and menu spacing constants. |
| [View/Common/LayoutView.mc](source/View/Common/LayoutView.mc), [RootView.mc](source/View/Common/RootView.mc) | Typed XML-element access, API 3.1-compatible visibility/drawing, and root-view lifecycle helpers. |
| [Controller/Common/RootController.mc](source/Controller/Common/RootController.mc) | Shared reminder toggle and settings navigation. |
| [View/Screens/Water/WaterView.mc](source/View/Screens/Water/WaterView.mc), [Reminder/ReminderView.mc](source/View/Screens/Reminder/ReminderView.mc), [GoalReached/GoalReachedView.mc](source/View/Screens/GoalReached/GoalReachedView.mc) | Main screen with separate goal/consumed labels, reminder screen with remaining milliliters, and dedicated goal-completed screen. |
| [Controller/Screens/WaterController.mc](source/Controller/Screens/WaterController.mc), [ReminderController.mc](source/Controller/Screens/ReminderController.mc) | Root-screen input delegates; the main controller also provides the next reminder for display. |
| [View/Screens/Goal/GoalView.mc](source/View/Screens/Goal/GoalView.mc), [Interval/IntervalView.mc](source/View/Screens/Interval/IntervalView.mc), [Time/TimeView.mc](source/View/Screens/Time/TimeView.mc) | Editor screens; one time view serves both start and end settings. |
| [Controller/Screens/GoalController.mc](source/Controller/Screens/GoalController.mc), [IntervalController.mc](source/Controller/Screens/IntervalController.mc), [TimeController.mc](source/Controller/Screens/TimeController.mc) | Setting-specific ranges, digit rules, and time conversion on save. |
| [Controller/Screens/ServingController.mc](source/Controller/Screens/ServingController.mc), [View/Screens/Serving/ServingView.mc](source/View/Screens/Serving/ServingView.mc) | Serving-size editor with 50 ml steps, bounds, validation, and shared numeric presentation. |
| [View/Screens/GarminScreens/SettingsMenu.mc](source/View/Screens/GarminScreens/SettingsMenu.mc), [DaysMenu.mc](source/View/Screens/GarminScreens/DaysMenu.mc) | Native Garmin settings and weekday menus. |
| [Controller/Screens/GarminScreens/SettingsController.mc](source/Controller/Screens/GarminScreens/SettingsController.mc), [DaysController.mc](source/Controller/Screens/GarminScreens/DaysController.mc) | Open editors, toggle settings/days, and refresh menu values. |
| [Controller/Components/NumberController.mc](source/Controller/Components/NumberController.mc), [DigitController.mc](source/Controller/Components/DigitController.mc) | Shared draft editing, confirmation, cancellation, and button handling. |
| [View/Components/NumberEditor.mc](source/View/Components/NumberEditor.mc), [DigitEditor.mc](source/View/Components/DigitEditor.mc) | Reusable numeric presentation and active-digit/error rendering. |
| [View/Components/WaterFrame/WaterFrame.mc](source/View/Components/WaterFrame/WaterFrame.mc) | Shared root-screen header, errors, and control hints. |
| [View/Components/SettingsList.mc](source/View/Components/SettingsList.mc), [SettingsTitle/SettingsTitle.mc](source/View/Components/SettingsTitle/SettingsTitle.mc), [SettingsItem/SettingsItem.mc](source/View/Components/SettingsItem/SettingsItem.mc) | Menu value formatting/refresh, headers, and focused rows. |

### Resources and project files

| Files | Purpose |
| --- | --- |
| [source/View/Screens/](source/View/Screens/) | Screen-specific layouts beside their views: `Water/water.xml`, `Reminder/reminder.xml`, `GoalReached/goal-reached.xml`, `Goal/goal.xml`, `Serving/serving.xml`, `Interval/interval.xml`, and `Time/time.xml`. |
| [source/View/Components/](source/View/Components/) | Reusable layouts beside their components: `WaterFrame/water-frame.xml`, both menu headers in `SettingsTitle/`, and `SettingsItem/menu-item.xml`. |
| [resources/properties.xml](resources/properties.xml), [settings.xml](resources/settings.xml) | Persistent defaults/schema and mobile-settings fields/ranges. |
| [resources/strings.xml](resources/strings.xml) | Spanish UI text and background-accessible messages. |
| [resources/drawables.xml](resources/drawables.xml), [icon.svg](resources/icon.svg) | Background/focus drawables and launcher icon. |
| [manifest.xml](manifest.xml) | App identity, entry point, device, minimum API, language, and background permission. |
| [monkey.jungle](monkey.jungle) | Compiler source, test, resource, and manifest paths. |
| [Makefile](Makefile), [run-simulator.sh](run-simulator.sh) | Strict builds, simulator execution, tests, and export; the script builds before running. |
| [run-screen-debug.sh](run-screen-debug.sh) | Isolated screen-preview build and launch with a required screen name and accelerated reminders. |
| [z_debug-launch-helper.sh](z_debug-launch-helper.sh) | Shared internal helper for temporary accelerated-debug configuration, compilation, loading, and cleanup. |
| [.vscode/launch.json](.vscode/launch.json) | Monkey C debugger configuration for `fr645`. |
| [tests/ScheduleTests.mc](tests/ScheduleTests.mc) | Regression tests for configuration/types, calendar boundaries, reminder tolerance/spacing/checkpoints, daily intake and goal suspension/resumption, editor persistence, menu toggles, and screen rendering. Tests that modify settings/storage restore them after failures. |

XML layouts use `StackText` labels without coordinates. `LayoutView.setVerticalLayout` groups their IDs into header, content, and footer rows. It measures the current text/font, wraps long text, skips hidden elements, and centers the content block between the header and controls with the fixed 6 px `Theme.STACK_GAP` spacing. IDs in the same row remain horizontal (for example, time digits); root-screen content follows XML order through `WaterFrame`. Root screens reserve a smaller outer margin than editors to fit four content rows on the 240 px Forerunner 645 display. Menu headers and items use the same stack within Garmin's drawing area. Content that exceeds the available height raises an explicit layout error rather than overlapping controls. Layout and theme changes require recompilation; keep XML colors consistent with the runtime palette.

Editor screens call `LayoutView.setEditorLayout` with their compiled XML layout, drawing context, and content rows only. The shared method configures the `title`, `editHint`, and `confirmHint` (digit editors) or `saveHint` (numeric editors), and calculates the common outer margin. Individual editors do not repeat positioning formulas or header/footer configuration.

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

3. Use the simulated watch buttons as described in **Watch controls and settings**: **START** toggles reminders or confirms a selection, **UP/MENU** opens settings, **UP/DOWN** changes values, and **BACK** returns or cancels. Starting with a zero daily total, set the goal to **250 ml** and the serving to **150 ml**, then select **Registrar toma**: the main screen should show **Objetivo: 250 ml** and **Llevas: 150 ml**. Register another serving: the dedicated **Objetivo cumplido** screen should show **Llevas: 300 ml**. Raise the goal above the total to return to the main screen. Restore your intended settings afterward. Check the interval, time window, and weekdays, then return to the watch face to exercise background reminders.

### Simulator script reference

Both scripts resolve paths relative to their own directory, so they can be invoked from another working directory. They require the SDK, Java, developer key, and an already-running simulator described above. Neither starts the simulator or attaches a debugger.

| Command | Behavior | Executable |
| --- | --- | --- |
| `./run-simulator.sh` | Build and run with the project's default configuration. | `bin/drink-water.prg` |
| `./run-simulator.sh debug` | Temporarily enable accelerated reminders, with normal startup-screen selection. | `bin/drink-water-debug.prg` |
| `./run-screen-debug.sh screen` | Temporarily preview the required screen with accelerated reminders enabled. | `bin/drink-water-debug.prg` |

The simulator launcher accepts only the optional `debug` argument; the screen launcher accepts exactly one screen name and needs no `debug` flag. Configure tool paths through environment variables, for example `SDK_HOME="/path/to/sdk" ./run-screen-debug.sh goal`, or export `SDK_HOME`, `JAVA_HOME`, and `DEVELOPER_KEY` beforehand. Additional arguments, including Make variable assignments, are rejected. The scripts rebuild on every launch, stop if compilation fails, and do not run tests. Temporary configurations are cleaned up on exit; compiled executables and changes made through the app's controls persist.

### Previewing a specific screen

With the simulator already open, run:

```sh
./run-screen-debug.sh goal
./run-screen-debug.sh reminder
./run-screen-debug.sh startTime
```

The screen name is mandatory. The launcher no longer reads [debug-screen.conf](debug-screen.conf); pass the desired screen explicitly. The former `run-debug.sh` name and `run-simulator.sh --screen` interface have been replaced by [run-screen-debug.sh](run-screen-debug.sh).

The launcher generates a temporary configuration with screen preview and accelerated reminders enabled, compiles `bin/drink-water-debug.prg`, and loads it without a debugger. It never edits the normal configuration or overwrites `bin/drink-water.prg`. Temporary configuration files are removed on exit, including build/load failures or interruption. The compiled preview remains available for `make debug-run`. Use `./run-simulator.sh` to rebuild and launch the normal app afterward.

The terminal should print `DrinkWater DEBUG: pantalla goal` (or the selected name) when the preview starts. The command normally stays active until the app closes. If compilation succeeds but the simulator remains on the Garmin logo without that startup message, interrupt the script, close and reopen the simulator, and run the script again; the SDK loader can remain waiting without reporting an error when the simulator is stuck.

For persistent preview selection in regular non-release builds or VS Code debugging, edit [source/App/DebugConfig.mc](source/App/DebugConfig.mc):

```monkeyc
const SCREEN_ENABLED = true;
const SCREEN = "goal";
```

Then run `./run-simulator.sh` with the simulator already open. No debugger is required. Every configuration or layout change requires rebuilding; `make run` alone reloads the previous build.

Available screens: `water`, `reminder`, `goalReached`, `goal`, `serving`, `interval`, `startTime`, `endTime`, `settings`, and `days`. The two time options share a layout but use their respective titles and values. Unknown screen names fail explicitly instead of opening another screen.

Preview mode opens the real view with its normal controller. Persistent previews without accelerated debug use current saved settings/intake; the screen launcher uses the fixed goal and separate initial intake described below. Controls still save changes, except for the fixed debug goal. Automatic root-screen switching is suppressed for the entire preview session, so a reminder or daily-goal update does not replace the selected screen. Saving or cancelling an editor opened as the initial screen closes the app; screens opened from a menu return to that menu as usual.

Set `SCREEN_ENABLED = false` in [source/App/DebugConfig.mc](source/App/DebugConfig.mc) to restore normal startup and automatic screen switching for regular builds. The debug launchers ignore these persistent defaults for their own isolated builds. [run-screen-debug.sh](run-screen-debug.sh) always enables accelerated reminders; persistent previews configured in the source remain independent of `DebugConfig.DEBUG`. Garmin's `(:debug)`/`(:release)` annotations disable screen previews in release builds, including `make package`, even when `SCREEN_ENABLED` is true. Regular non-release simulator builds and VS Code debug launches both honor the persistent configuration.

For interactive debugging in VS Code, install/configure Garmin's Monkey C extension with your SDK and developer key, select **Debug Bebe agua (Forerunner 645)**, and press **F5**. The configuration in [.vscode/launch.json](.vscode/launch.json) targets `fr645` and pauses at launch (`stopAtLaunch`); resume execution to interact with the app.

### Accelerated reminder debug mode

With the simulator already open, run:

```sh
./run-simulator.sh debug  # Normal startup screen, with an accelerated reminder
./run-simulator.sh        # Normal build, without accelerated reminders
```

The `debug` argument temporarily enables `DebugConfig.DEBUG` from [source/App/DebugConfig.mc](source/App/DebugConfig.mc), without editing source files. [run-simulator.sh](run-simulator.sh) and [run-screen-debug.sh](run-screen-debug.sh) share the temporary-configuration build path through [z_debug-launch-helper.sh](z_debug-launch-helper.sh) and produce `bin/drink-water-debug.prg`; `make debug-run` reloads whichever debug mode was built last. Both debug launchers enable accelerated reminders, but only the screen launcher forces a startup screen. The normal executable remains separate. Default builds keep both debug features disabled, and release builds always disable accelerated reminders.

This mode fixes the goal at **2000 ml** without changing the saved normal-mode goal. Each app opening initializes a separate `debugDailyIntake` total to **1800 ml** for the current day; registering servings increases that debug total and never modifies real `dailyIntake`. The goal shown in settings is fixed and cannot be edited in debug. Normal mode retains its saved goal, interval, and intake.

The first reminder targets the next minute boundary (1-60 seconds after opening), outside normal day/time/interval restrictions but still respecting enabled/valid settings and the daily goal. Every background callback re-arms the next debug reminder for the earliest allowed time. Garmin requires at least **five minutes between background executions**, so later reminders may need to wait five minutes; debug does not bypass that platform limit. Scheduling uses Garmin's registered event time; callback validation uses `Background.getLastTemporalEventTime()`, because the one-shot registration may already be cleared when the event fires. No one-off stored deadline is needed. Reaching 2000 ml stops reminders for that day. The terminal prints `DrinkWater DEBUG: aviso en ... s` at startup when a reminder is scheduled. Closing the app allows the background wake dialog to be observed; reopening debug resets its initial consumption to 1800 ml.

When the in-app reminder screen becomes visible, the console prints `DrinkWater INFO: pantalla de recordatorio visible`, including in screen-preview mode and when returning from a menu. This message is emitted on screen entry, not on every redraw, and is distinct from scheduling a reminder or requesting Garmin's wake dialog.

To run the regression tests explicitly, leave the simulator open and execute:

```sh
make test
```

The test target compiles a separate `bin/drink-water-tests.prg`, requires a complete `PASSED` summary with no failures/errors, and records output in `bin/test-output.log`; it handles the known macOS `monkeydo` exit-code-1 anomaly only when that summary is present.

The simulator is useful for UI, settings, and scheduling checks, but does not establish real-watch notification timing, firmware behavior during activities/Do Not Disturb, or battery consumption. Clock changes also need real-device validation.

### Installing on the watch

1. Confirm that the watch is a **Forerunner 645 (non-Music)** and update its firmware if necessary. Other devices need their own manifest target and compatible build.
2. Keep the defaults in [source/App/DebugConfig.mc](source/App/DebugConfig.mc) disabled and run `make build`. Use the resulting `bin/drink-water.prg`, not the debug/test program or the `.iq` package.
3. Connect the watch to your computer with a **USB data cable**. Wait for its storage to appear in Finder; if it does not, check the cable and the watch's USB mode.
4. Open the watch's **GARMIN/APPS** folder and copy `bin/drink-water.prg` into it.
5. Safely eject the watch, disconnect the cable, and wait for it to finish processing the app.
6. On the watch, press **START**, find **Bebe agua** in the app list, and open it once to initialize scheduling.
7. Check the goal, serving size, interval, start/end times, weekdays, and enabled state. Use **Registrar toma** after drinking; exit with **BACK** to leave reminders running in the background until the daily goal is reached.

If the app does not appear or cannot open, check the device model, firmware, successful build output, and destination folder. The simulator cannot guarantee real-device compatibility or background behavior.

Mobile settings depend on Connect IQ settings metadata; USB installation is not Connect IQ Store publication and does not by itself guarantee access to those settings in the mobile app. All settings can be configured on the watch. Store publication is a separate, manual step. Generated files live in `bin/`, not in the source tree.
