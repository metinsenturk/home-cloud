# Entrypoint Override Architecture

## How It Works

This Freqtrade deployment uses a custom **Python entrypoint script** that **automatically initializes** the bot on first start. Without this automation, you would need to manually run three commands before starting the bot.

**The Problem:**
- The official `freqtradeorg/freqtrade` Docker image requires `config.json` to exist
- It does NOT auto-initialize on first run
- Manual workaround: `docker exec freqtrade freqtrade create-userdir && freqtrade new-config`

**The Solution:**
- Custom [entrypoint.py](entrypoint.py) script that overrides the image's default entrypoint
- Script automatically runs on container start, **before** the bot launches
- If `config.json` is missing, it:
  1. Creates the user directory structure
  2. Generates a new config.json with defaults
  3. Patches the config to use Kraken (avoids Binance geo-restrictions)
  4. Launches freqtrade with all settings configured

## Docker Entrypoint Override in Compose

### How Docker Merges Entrypoint and Command

**Your docker-compose.yml has two fields:**

```yaml
entrypoint: python3 /entrypoint.py          # Overrides the image's default entrypoint
command: freqtrade trade --config ...       # Args passed to the entrypoint script
```

**Docker combines them into a single invocation:**
```bash
python3 /entrypoint.py freqtrade trade --config user_data/config.json --strategy SampleStrategy
```

### How the Script Processes This

1. **Python script receives the command as arguments:**
   ```python
   sys.argv = ['/entrypoint.py', 'freqtrade', 'trade', '--config', 'user_data/config.json', '--strategy', 'SampleStrategy']
   ```

2. **Script checks if config.json exists:**
   - ✅ If YES: Skips initialization, proceeds to launch freqtrade
   - ❌ If NO: Runs full initialization (create-userdir → new-config → exchange patch)

3. **Script launches freqtrade with the remaining arguments:**
   ```python
   subprocess.run(['freqtrade', 'trade', '--config', 'user_data/config.json', '--strategy', 'SampleStrategy'])
   ```

4. **Freqtrade runs with initialized config and returns exit code to Docker**

## First Start Initialization Output

```
[entrypoint] config.json not found. Running first-time setup...
[entrypoint] Running: Creating user directory structure...
2026-02-28 02:28:26,182 - freqtrade - INFO - freqtrade docker-2026.2-dev-f7b11c51
2026-02-28 02:28:27,677 - freqtrade - INFO - freqtrade docker-2026.2-dev-f7b11c51
[entrypoint] Generating config.json with defaults...
2026-02-28 02:28:34,965 - freqtrade.configuration.deploy_config - INFO - Writing config to `/freqtrade/user_data/config.json`.
[entrypoint] Updating exchange to kraken...
[entrypoint] Switched exchange from binance to kraken
[entrypoint] First-time setup complete.
[entrypoint] Starting freqtrade...
2026-02-28 02:36:35,935 - freqtrade - INFO - freqtrade docker-2026.2-dev-f7b11c51
...
```

## Subsequent Starts

Once `config.json` exists, initialization is skipped:
```
[entrypoint] config.json found at /freqtrade/user_data/config.json. Skipping initialization.
[entrypoint] Starting freqtrade...
```

## Using Different Freqtrade Commands

Because the entrypoint is flexible, you can use it with any freqtrade subcommand:

**Run backtesting:**
```bash
docker compose -f docker-compose.yml run --rm freqtrade \
  python3 /entrypoint.py freqtrade backtesting --config user_data/config.json --strategy SampleStrategy
```

**Download data:**
```bash
docker compose -f docker-compose.yml run --rm freqtrade \
  python3 /entrypoint.py freqtrade download-data --config user_data/config.json --pairs BTC/USDT ETH/USDT
```

**Show configuration:**
```bash
docker compose -f docker-compose.yml run --rm freqtrade \
  python3 /entrypoint.py freqtrade show-config
```

The entrypoint script handles all of these—it initializes config if needed, then hands off to freqtrade with your requested command.
