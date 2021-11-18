# SurfTimer-discord

![Downloads](https://img.shields.io/github/downloads/Sarrus1/SurfTimer-discord/total?style=flat-square) ![Last commit](https://img.shields.io/github/last-commit/Sarrus1/SurfTimer-discord?style=flat-square) ![Open issues](https://img.shields.io/github/issues/Sarrus1/SurfTimer-discord?style=flat-square) ![Closed issues](https://img.shields.io/github/issues-closed/Sarrus1/SurfTimer-discord?style=flat-square) ![Size](https://img.shields.io/github/repo-size/Sarrus1/SurfTimer-discord?style=flat-square) ![GitHub Workflow Status](https://img.shields.io/github/workflow/status/Sarrus1/SurfTimer-discord/Compile%20with%20SourceMod?style=flat-square)

## Description

Sends nice Discord embeded messages when a new map record is set.
The messages will look like this:

![Preview](https://raw.githubusercontent.com/Sarrus1/SurfTimer-discord/master/img/desc.png)

## Requirements

- Sourcemod and Metamod
- [SurfTimer-Official (main project or Sad's fork)](https://github.com/surftimer/Surftimer-Official)
- [SM-RipExt](https://github.com/ErikMinekus/sm-ripext/releases/latest)

## Installation

1. Grab the latest release from the release page and unzip it in your sourcemod folder.
2. Restart the server or type `sm plugins load SurfTimer-discord` in the console to load the plugin.
3. The config file will be automatically generated at `cfg/sourcemod/SurfTimer-discord.cfg`
4. In the config file, configure your Discord Webhook and your Steam API key (optional, you can get it [here](https://steamcommunity.com/dev/apikey)).

## Configuration

- You can modify the phrases in addons/sourcemod/translations/SurfTimer-discord.phrases.txt.
- Once the plugin has been loaded, you can modify the cvars in cfg/sourcemod/SurfTimer-discord.cfg.
- To use Discord mentions, follow [this tutorial](https://discordhelp.net/role-id) to get the role's ID and use `<@&role_id>` in the .cfg file. You can use `@here` and `@everyone` normally.

## Usage

 - You can use the `sm_ck_discordtest` command to test the messages.