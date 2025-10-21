# Grubify

A powerful Bash-based tool for creating and installing custom GRUB bootloader themes with extensive customization options.

## Table of Contents

- [Features](#features)
- [Previews](#previews)
- [Dependencies](#dependencies)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
  - [Pre-made Configurations](#pre-made-configurations)
  - [Configuration References](#configuration-references)
- [Troubleshooting](#troubleshooting)
- [License](#license)
- [Contributing](#contributing)
- [Credits](#credits)

## Features

- **Custom Backgrounds**: File-based or solid color backgrounds with automatic scaling to fit screen
- **Advanced Container Effects**: Blurred or solid containers with configurable positioning and border radius
- **Icon Support**: 100+ OS/distribution icons from Papirus and Tela Circle icon themes
- **Font Management**: Automatic download and conversion of Unifont and Terminus fonts
- **Pre-made Layouts**: Center, left, and right-aligned configurations
- **Progress Indicators**: Countdown timer, progress bar, circular progress with custom logo or personal avatar

## Previews

|||
|:-:|:-:|
|![Preview 1](https://raw.githubusercontent.com/lshung/grubify-assets/master/previews/center-blur-peach.png)|![Preview 2](https://raw.githubusercontent.com/lshung/grubify-assets/master/previews/center-solid-flamingo.png)|
|Center Blur Peach|Center Solid Flamingo|
|![Preview 3](https://raw.githubusercontent.com/lshung/grubify-assets/master/previews/left-blur-maroon.png)|![Preview 4](https://raw.githubusercontent.com/lshung/grubify-assets/master/previews/left-solid-sapphire.png)|
|Left Blur Maroon|Left Solid Sapphire|
|![Preview 5](https://raw.githubusercontent.com/lshung/grubify-assets/master/previews/right-blur-mauve.png)|![Preview 6](https://raw.githubusercontent.com/lshung/grubify-assets/master/previews/right-solid-green.png)|
|Right Blur Mauve|Right Solid Green|

## Dependencies

- **Linux** with **Bash**
- **GRUB** version 2
- **GRUB tools**: Font conversion and configuration
- **FFmpeg**: Image processing and manipulation
- **rsvg**: Converting .svg to .png
- **curl** or **wget**: Downloading assets

Grubify does not automatically install dependencies, it just shows the error messages if any of them is missing.

## Installation

1. Clone the repository:
   ```bash
   rm -rf ~/.local/lib/grubify && mkdir -p ~/.local/lib/grubify
   git clone https://github.com/lshung/grubify.git ~/.local/lib/grubify
   mkdir -p ~/.local/bin/
   ln -sf ~/.local/lib/grubify/run ~/.local/bin/grubify
   ```
2. Run the installation script:
    ```bash
   grubify install
   ```
   If you encounter error `Command not found: grubify`, it means that `$HOME/.local/bin` is not in your `PATH`, so you can not use the command `grubify` directly. See [Troubleshooting Command Not Found Error](#command-not-found-error) to fix or run the command below instead:
   ```bash
   cd ~/.local/lib/grubify && ./run install
   ```

## Usage

### Commands
```bash
grubify install                 # Install theme or update theme with a new configuation
grubify remove                  # Remove theme (coming soon)
grubify menu-valign-center      # Vertically center menu items within container (when the total number of menu entries has changed).
```
Use the commands below to generate a single component of a GRUB theme. Your can preview it before running `grubify install` finally. This will save your time in the configuration process.
```bash
grubify gen-background          # Generate background image only
grubify gen-circular-progress   # Generate circular progress assets only
grubify gen-distro-icons        # Generate distro icons only
grubify gen-fonts               # Generate fonts only
grubify gen-selected-item       # Generate selected item assets only
grubify gen-theme-file          # Generate file 'theme.txt' only
```
All commands above can be used with option `--verbose` for defail information.

### Options
```bash
grubify --help       # Show help
grubify --version    # Show version
```

## Configuration

Create a configuration file at `~/.config/grubify/grubify.conf` to customize your theme.
```bash
mkdir -p ~/.config/grubify
touch ~/.config/grubify/grubify.conf
```
After editing the file `~/.config/grubify/grubify.conf`, to update the theme with new settings, please run command:
```bash
grubify install
```

### Pre-made Configurations

You can use one of the three ready-to-use configurations from the `pre-made/` directory:

- **`center.conf`**: Centered layout with blurred container
- **`left.conf`**: Left-aligned layout with full-height container
- **`right.conf`**: Right-aligned layout with full-height container

Copy any of these to `~/.config/grubify/grubify.conf` and customize as needed. For example:
   ```bash
   cd ~/.local/lib/grubify
   cp pre-made/left.conf ~/.config/grubify/grubify.conf
   ```

### Configuration References

**Note:**
   - Many configuration values accept pixels, percentage, or mixture of both (e.g., `100`, `50%`, `50%+20`, `30%-50`). However, some configurations only accept pixels. So read the description of them carefully.
   - If the configuration value is in pixels or mixed, do not append `px` (e.g., `100` not `100px`, `30%-50` not `30%-50px`).
   - The font sizes of **Terminus** are limited to specific values: 12, 14, 16, 18, 20, 22, 24, 28, 32.

| Name | Description | Default |
|------|-------------|---------|
| **Theme Colors** | | |
| `THEME_BACKGROUND_COLOR` | Reference color for background | `#313244` |
| `THEME_TEXT_COLOR` | Reference color for text | `#cdd6f4` |
| `THEME_ACCENT_COLOR` | Reference color for accent (highlight) | `#fab387` |
| **Screen** | | |
| `SCREEN_WIDTH` | Width of screen in pixels | `1920` |
| `SCREEN_HEIGHT` | Height of screen in pixels | `1080` |
| `SCREEN_COLOR_DEPTH` | Color depth of screen in bits | `32` |
| **Background** | | |
| `BACKGROUND_TYPE` | Background type: 'file' or 'solid' | `file` |
| `BACKGROUND_FILE` | Path to background image (only used if BACKGROUND_TYPE is 'file'). If set BACKGROUND_TYPE to 'file' but BACKGROUND_FILE is not set, the default background image will be downloaded and used | `` |
| `BACKGROUND_COLOR` | Background color (only used if BACKGROUND_TYPE is 'solid') | `#000000` |
| **Container** | | |
| `CONTAINER_WIDTH` | Width of container in pixels, percentage, or mixture of both | `40%` |
| `CONTAINER_HEIGHT` | Height of container in pixels, percentage, or mixture of both | `40%` |
| `CONTAINER_LEFT` | Left position of container in pixels, percentage, or mixture of both | `30%` |
| `CONTAINER_TOP` | Top position of container in pixels, percentage, or mixture of both | `30%` |
| `CONTAINER_BORDER_RADIUS` | Border radius of container in pixels | `50` |
| `CONTAINER_TYPE` | Container type: 'blur' or 'solid' | `blur` |
| `CONTAINER_BLUR_SIGMA` | Strength of the blur effect (only used if CONTAINER_TYPE is 'blur') | `30` |
| `CONTAINER_BLUR_BRIGHTNESS` | Brightness of container after blur (only used if CONTAINER_TYPE is 'blur') | `0` |
| `CONTAINER_BLUR_CONTRAST` | Contrast of container after blur (only used if CONTAINER_TYPE is 'blur') | `1` |
| `CONTAINER_COLOR` | Solid color of container (leave empty to use THEME_BACKGROUND_COLOR) | `` |
| **Terminal** | | |
| `TERMINAL_FONT_NAME` | Terminal font: 'Terminus Regular', 'Terminus Bold', or 'Unifont Regular' | `Terminus Regular` |
| `TERMINAL_FONT_SIZE` | Terminal font size | `14` |
| **Menu** | | |
| `MENU_WIDTH` | Width of menu in pixels, percentage, or mixture of both | `30%` |
| `MENU_HEIGHT` | Height of menu in pixels, percentage, or mixture of both | `30%` |
| `MENU_LEFT` | Left position of menu in pixels, percentage, or mixture of both | `35%` |
| `MENU_TOP` | Top position of menu in pixels, percentage, or mixture of both | `35%` |
| `MENU_VALIGN_CENTER` | Vertically center menu items within container. If set to 'yes', MENU_HEIGHT and MENU_TOP will be ignored | `no` |
| **Menu Items** | | |
| `ITEM_FONT_NAME` | Item font: 'Terminus Regular', 'Terminus Bold', or 'Unifont Regular' | `Unifont Regular` |
| `ITEM_FONT_SIZE` | Item font size | `16` |
| `ITEM_COLOR` | Text color of items (leave empty to use THEME_TEXT_COLOR) | `` |
| `SELECTED_ITEM_FONT_NAME` | Selected (focused) item font: 'Terminus Regular', 'Terminus Bold', or 'Unifont Regular' | `Unifont Regular` |
| `SELECTED_ITEM_FONT_SIZE` | Selected (focused) item font size | `16` |
| `SELECTED_ITEM_COLOR` | Text color of selected (focused) item (leave empty to use THEME_BACKGROUND_COLOR) | `` |
| `SELECTED_ITEM_BACKGROUND_COLOR` | Background color of selected (focused) item (leave empty to use THEME_ACCENT_COLOR, or 'none' for transparent) | `` |
| `ITEM_HEIGHT` | Height of item in pixels | `40` |
| `ITEM_PADDING` | Padding of menu item contents in pixels | `0` |
| `ITEM_SPACING` | Spacing between items in pixels | `10` |
| **Menu Icons** | | |
| `ICON_THEME` | Icon theme: 'papirus' or 'tela-circle' | `papirus` |
| `ICON_SIZE` | Size of icon in pixels (width and height are the same) | `32` |
| `ITEM_ICON_SPACE` | Space between icon and title text in pixels | `15` |
| **Grub Timeout** | | |
| `GRUB_TIMEOUT` | Timeout before auto-boot in seconds | `5` |
| **Countdown** | | |
| `COUNTDOWN_VISIBLE` | Show or hide countdown label. Accepted values: 'yes' or 'no' | `yes` |
| `COUNTDOWN_FONT_NAME` | Countdown font: 'Terminus Regular', 'Terminus Bold', or 'Unifont Regular' | `Unifont Regular` |
| `COUNTDOWN_FONT_SIZE` | Countdown font size | `16` |
| `COUNTDOWN_TEXT` | Content of countdown label | `Auto-boot in %d seconds` |
| `COUNTDOWN_WIDTH` | Width of countdown label in pixels, percentage, or mixture of both | `30%` |
| `COUNTDOWN_LEFT` | Left position of countdown label in pixels, percentage, or mixture of both | `35%` |
| `COUNTDOWN_TOP` | Top position of countdown label in pixels, percentage, or mixture of both | `85%` |
| `COUNTDOWN_ALIGN` | Alignment of countdown label. Accepted values: 'left', 'center', or 'right' | `center` |
| `COUNTDOWN_COLOR` | Text color of countdown label (leave empty to use THEME_TEXT_COLOR) | `` |
| **Progress Bar** | | |
| `PROGRESS_BAR_VISIBLE` | Show or hide progress bar. Accepted values: 'yes' or 'no' | `yes` |
| `PROGRESS_BAR_WIDTH` | Width of progress bar in pixels, percentage, or mixture of both | `30%` |
| `PROGRESS_BAR_HEIGHT` | Height of progress bar in pixels, percentage, or mixture of both | `25` |
| `PROGRESS_BAR_LEFT` | Left position of progress bar in pixels, percentage, or mixture of both | `35%` |
| `PROGRESS_BAR_TOP` | Top position of progress bar in pixels, percentage, or mixture of both | `90%` |
| `PROGRESS_BAR_FOREGROUND_COLOR` | Foreground color of progress bar (leave empty to use THEME_ACCENT_COLOR) | `` |
| `PROGRESS_BAR_BACKGROUND_COLOR` | Background color of progress bar (leave empty to use THEME_BACKGROUND_COLOR) | `` |
| `PROGRESS_BAR_BORDER_COLOR` | Border color of progress bar (leave empty to use THEME_BACKGROUND_COLOR) | `` |
| **Circular Progress** | | |
| `CIRCULAR_PROGRESS_VISIBLE` | Show or hide circular progress. Accepted values: 'yes' or 'no' | `no` |
| `CIRCULAR_PROGRESS_WIDTH` | Width of circular progress in pixels, percentage, or mixture of both. The height is the same as the width | `200` |
| `CIRCULAR_PROGRESS_CENTER_X` | The x position of circular progress center point in pixels, percentage, or mixture of both | `50%` |
| `CIRCULAR_PROGRESS_CENTER_Y` | The y position of circular progress center point in pixels, percentage, or mixture of both | `85%` |
| `CIRCULAR_PROGRESS_NUM_TICKS` | Number of ticks that make up a full circle | `30` |
| `CIRCULAR_PROGRESS_TICKS_DISAPPEAR` | Whether tick marks should progressively appear, or progressively disappear. Accepted values: 'true' or 'false' | `false` |
| `CIRCULAR_PROGRESS_START_ANGLE` | Starting angle in parrots (0-left, 64-bottom, 128-right, 192-top) | `192` |
| `CIRCULAR_PROGRESS_CENTER_COLOR` | Color of center bitmap (leave empty to use THEME_BACKGROUND_COLOR, or 'none' for transparent) | `` |
| `CIRCULAR_PROGRESS_TICK_COLOR` | Color of tick bitmap (leave empty to use THEME_ACCENT_COLOR, or 'none' for transparent) | `` |
| `CIRCULAR_PROGRESS_TICK_SIZE` | Size of tick bitmap in pixels (width and height are the same) | `10` |
| **Circular Progress Countdown** | | |
| `CIRCULAR_PROGRESS_COUNTDOWN_VISIBLE` | Show or hide circular progress countdown. Accepted values: 'yes' or 'no' | `no` |
| `CIRCULAR_PROGRESS_COUNTDOWN_FONT_NAME` | Circular progress countdown font: 'Unifont Regular' | `Unifont Regular` |
| `CIRCULAR_PROGRESS_COUNTDOWN_FONT_SIZE` | Font size of countdown label, should be an even number (not odd number) | `100` |
| `CIRCULAR_PROGRESS_COUNTDOWN_COLOR` | Text color of countdown label (leave empty to use THEME_ACCENT_COLOR) | `` |
| **Circular Progress Image** | | |
| `CIRCULAR_PROGRESS_IMAGE_VISIBLE` | Show or hide circular progress's center image. Accepted values: 'yes' or 'no' | `no` |
| `CIRCULAR_PROGRESS_IMAGE_WIDTH` | Width of center image in pixels, percentage, or mixture of both. The height is the same as the width | `160` |
| `CIRCULAR_PROGRESS_IMAGE_FILE` | File path of center image (can use icons from supported icon themes, e.g., just set 'icons/papirus/arch.svg'). Accepted extensions: .svg, .png (.svg will be converted to .png) | `` |

## Troubleshooting

### Command Not Found Error

If you encounter `Command not found: grubify` error, it means that `$HOME/.local/bin` is not in your `PATH`.

**For Bash users:**
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**For Zsh users:**
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Alternative solution:**
You can also run the tool directly without adding to PATH:
```bash
cd ~/.local/lib/grubify && ./run install
```

### Screen Resolution Issues

If your GRUB theme doesn't display correctly or appears distorted, the screen resolution might not be supported by GRUB. Read this [post](https://unix.stackexchange.com/questions/791227/changing-the-screen-resolution-of-grub-on-a-vmware-virtual-machine) to know why it happens.

**To check available resolutions:**

1. Boot into GRUB menu
2. Press `c` to enter GRUB command line
3. Run one of these commands:
   - `vbeinfo` (for older systems)
   - `videoinfo` (for newer systems)
4. Note the available resolution and color depth that you want to use
5. Update the file `~/.config/grubify/grubify.conf` with supported values:
   ```bash
   SCREEN_WIDTH=
   SCREEN_HEIGHT=
   SCREEN_COLOR_DEPTH=
   ```
6. Run command below to update the theme with new settings:
    ```bash
   grubify install
   ```

### Permission Issues

If you encounter permission errors:

1. Ensure you have sudo access
2. Check that `/etc/default/grub` is writable
3. Verify GRUB themes directory permissions

### Menu Valign Center Issues

If your menu items are no longer vertically centered within the container, this happens because the total number of menu entries has changed. Common causes include:

- **Snapper snapshots**: Snapper automatically creates boot entries for system snapshots
- **Kernel updates**: New kernel versions add additional boot entries
- **Manual GRUB entries**: Custom boot entries added to GRUB configuration
- **System updates**: Package managers may add or remove boot entries

**How to fix:**

1. **Manual fix**: Run the command to recalculate and update menu positioning:
   ```bash
   grubify menu-valign-center
   ```

2. **Automatic fix**: Add a **root** cron job to automatically run the command above.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## Credits

- [GRUB theme manual](https://www.gnu.org/software/grub/manual/grub/html_node/Theme-file-format.html)
- Default background image from [Freepik](https://www.freepik.com/free-ai-image/anime-style-portrait-traditional-japanese-samurai-character_186699606.htm).
- Icon themes: [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) and [Tela-circle](https://github.com/vinceliuice/Tela-circle-icon-theme)
- Fonts: [Unifont](https://unifoundry.com/unifont/index.html) and [Terminus](https://terminus-font.sourceforge.net/)
