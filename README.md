[Baca dalam Bahasa Indonesia](README-id.md)

# AI-CLI Selector & Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Style Guide](https://img.shields.io/badge/code%20style-shellcheck-orange.svg)](https://www.shellcheck.net/)

A central menu to **run** and **install** all your favorite command-line AI tools. Forget remembering a dozen different commands, just run `ai-select`.

![Demo](assets/ai-select.gif)

---

## ✨ Key Features

- **Smart Launcher Mode:** The `ai-select` command automatically detects your installed AI tools and presents them in a menu for instant execution.
- **Robust Installer Mode:** The `ai-select install` command opens an interface to install new AI tools, complete with intelligent fallback logic.
- **Modern Interactive UI:** Powered by `gum` for a smooth user experience.
- **Multi-Platform Support:** Designed to work across various Linux distributions and macOS.
- **Easy to Extend:** Adding a new AI-CLI to the list is as simple as editing a single configuration file.

## 🚀 Quick Install

Install `ai-select` onto your system with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/aldiipratama/ai-cli-selector/main/install.sh | sh
```

![Installation Demo](assets/ai-select-install.gif)

You can run this command from any directory. It will automatically install the files to the correct location in your home directory (`~/.local/share` and `~/.local/bin`).

The installation script will place the `ai-select` command in `~/.local/bin`. Make sure this directory is in your system's PATH.

## 🎮 Usage

Once installed, you can use `ai-select` from any directory.

### Running AI Tools (Launcher Mode)

Simply run the command without arguments to open the launcher menu. This menu will only show the AI tools that are already installed on your system.

```bash
ai-select
```

Choose one, and the script will execute it immediately.

### Installing New AI Tools (Installer Mode)

To add, update, remove, or reinstall AI tools, use the `install` argument.

```bash
ai-select install
```

This will open the full installation menu, allowing you to select tools from the master list.

### Updating the Tool

To update `ai-select` to the latest version, including the list of available AI tools, run:

```bash
ai-select update
```

![Update Demo](assets/ai-select-update.gif)

This will fetch the latest version of the script and its configuration from GitHub.

## 🔧 Adding or Modifying an AI-CLI

All AI tool configurations are stored in the file: `~/.local/share/ai-cli-selector/data/ai-metadata.conf`.

To add a new AI, simply add a new "block" to the end of that file. The format is as follows:

```ini
[YOUR_AI]
name=Display Name
command=cli_command
description=Short description
preferred_source=main_install_method
alt_sources=pip|aur
test_command=cli_command --version
...
```

## 🤝 Contributing

Contributions, issues, and feature requests are highly appreciated! Feel free to check the [issues page](https://github.com/aldiipratama/ai-cli-selector/issues).

## 📜 License

This project is licensed under the **MIT License**. See the `LICENSE` file for details.

## ❤️ Credits

This project was created and is maintained with heart by:

- **[aldiipratama](https://github.com/aldiipratama)** (Creator).
- **[Gemini](https://gemini.google.com)** as my personal assistant.
